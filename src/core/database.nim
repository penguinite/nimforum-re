import db_connector/db_sqlite
import std/[os, strutils]
import user, auth, categories, configs

type
  TCrud* {.deprecated: "use sqlCreate/sqlRead/sqlUpdate/sqlDelete".} = enum
    crCreate, crRead, crUpdate, crDelete

proc sqlCreate*(table: string, data: varargs[string,`$`]): SqlQuery =
  var
    fields = "INSERT INTO " & table & "("
    vals = ""

  for i, ch in data:
    if i > 0:
      fields.add(", ")
      vals.add(", ")
    fields.add(ch)
    vals.add('?')
  return sql(fields & ") values (" & vals & ");")

proc sqlRead*(table: string, data: varargs[string,`$`]): SqlQuery =
  var statement = "SELECT "
  for i, ch in data:
    if i > 0: statement.add(", ")
    statement.add(ch)
  return sql(statement & " FROM " & table & ";")

proc sqlUpdate*(table: string, data: varargs[string,`$`]): SqlQuery =
  var statement = "UPDATE " & table & " SET "
  for i, ch in data:
    if i > 0: statement.add(", ")
    statement.add(ch)
    statement.add(" = ?")
  return sql(statement & " where id = ?;")

proc sqlDelete*(table: string): SqlQuery =
  return sql("DELETE FROM " & table & " WHERE id = ?;")

proc crud*(operation: TCrud, table: string, data: varargs[string,`$`]): SqlQuery
  {.deprecated: "use sqlCreate/sqlRead/sqlUpdate/sqlDelete".} =
  ## Converts crud or whatever into a SqlQuery.
  {.warning[Deprecated]: off.}
  case operation
  of crCreate: return sqlCreate(table, data)
  of crRead: return sqlRead(table, data)
  of crUpdate: return sqlUpdate(table, data)
  of crDelete: return sqlDelete(table)
  {.warning[Deprecated]: on.}

proc init*(filename: string): DbConn =
  return open(connection=filename, user="", password="", database="nimforum")

proc init*(config: Config): DbConn =
  return init(config.dbPath)
  
proc userExists*(db: DbConn, id: string): bool = 
  if db.getRow(sql"SELECT id FROM person WHERE id = ?;", id)[0] == id:
    return true
  return false

proc userExistsName*(db: DbConn, name: string): bool = 
  if db.getRow(sql"SELECT name FROM person WHERE name = ?;", name)[0] == name:
    return true
  return false

proc createUserRaw*(db: DbConn, user: User): string =
  if not isValid(user):
    return "User isn't valid"

  let password = makePassword(user.pass, user.salt)
  var id = user.id
  while true:
    if db.userExists(id):
      id = makeId()
    else:
      break

  try:
    db.exec(
      sql"INSERT INTO person(id, name, password, email, salt, status, lastOnline) VALUES (?, ?, ?, ?, ?, ?, DATETIME('now'));",
      id, user.name, password, user.email, user.salt, $user.rank
    )
    return ""
  except CatchableError as err:
    return err.msg

proc createUser*(db: DbConn, user: User): bool =
  if db.createUserRaw(user) == "":
    return true
  else:
    return false

proc userNameToId*(db: DbConn, name: string): string =
  ## Automatically sanitizes usernames.
  return db.getRow(sql"SELECT id FROM person WHERE name = ?;", sanitizeName(name))[0]

proc getUser*(db: DbConn, id: string): User =
  assert db.getRow(sql"SELECT id FROM person WHERE id = ?;", id)[0] == id

  let row = db.getRow(
    sql"SELECT name, password, email, salt, status FROM person WHERE id = ?;",
    id
  )

  result.name = row[0]
  result.pass = row[1]
  result.email = row[2]
  result.salt = row[3]
  result.rank = toRank(row[4])
  result.id = id
  return result

# todo:
#proc getCategory*(db: DbConn, id: int): Category =

proc categoryExists*(db:DbConn, id: string): bool =
  return db.getRow(sql"SELECT id FROM category WHERE id = ?;", id)[0] == id

proc createCategory*(db: DbConn, name, description, color: string): bool =
  var id = makeId(8)
  while true:
    if db.categoryExists(id):
      id = makeId(8)
    else:
      break
  
  db.exec(
    sql"INSERT INTO category (id, name, description, color) values (?, ?, ?, ?);",
    id, name, description, color
  )

proc getXRows(db: DbConn, query: SqlQuery, limit: int = 15, args: varargs[string, `$`]): seq[Row] =
  var i = 0
  for row in db.rows(query, args):
    result.add(row)
    inc i
    if i == limit: break
  return result

proc getCategories*(db: DbConn): seq[Category] =
  ## Gets list of categories.
  const categoriesQuery = sql"""
      select c.*, count(thread.category)
      from category c
      left join thread on c.id == thread.category
      group by c.id;
    """
  for data in getXRows(db, categoriesQuery):
    result.add(
      Category(
        id: data[0], name: data[1], description: data[2], color: data[3],
        topicsCount: data[4].parseInt()))
  return result
  
proc createTable(db: DbConn, table: string, fields: varargs[string]) =
  var statement = "CREATE TABLE IF NOT EXISTS " & table & "("
  for field in fields:
    statement.add(field & ",")
  statement = statement[0..^2]
  statement.add(");")

  db.exec(sql(statement))

proc createVirtualTable(db: DbConn, table: string, fields: varargs[string]): bool =
  var statement = "CREATE VIRTUAL TABLE IF NOT EXISTS " & table & "("
  for field in fields:
    statement.add(field & ",")
  statement = statement[0..^2]
  statement.add(");")

  return db.tryExec(sql(statement))

proc setup*(filename: string = "nimforum.db"): DbConn =
  if fileExists(filename):
    var i = 0
    while true:
      inc(i)
      if not fileExists(filename & "-" & $i):
        copyFile(filename, filename & "-" & $i)
        removeFile(filename)
        break

  result = init(filename)

  # -- Category

  result.createTable(
      "category",
      "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids not integer
      "name varchar(100) not null",
      "description varchar(500) not null",
      "color varchar(10) not null"
  )

  discard result.createCategory("Unsorted", "No category has been chosen yet.", "")

  # -- Thread

  result.createTable(
    "thread",
    "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids not integer
    "name varchar(100) not null",
    "views integer not null",
    "modified timestamp not null default (DATETIME('now'))",
    "category integer not null default 0",
    "isLocked boolean not null default 0",
    "solution integer",
    "isDeleted boolean not null default 0",
    "isPinned boolean not null default 0",
    "foreign key (category) references category(id)",
    "foreign key (solution) references post(id)"
  )

  result.exec(sql"create unique index ThreadNameIx on thread (name);", [])

  # -- Person
  result.createTable(
    "person",
    "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids not integer
    "name varchar(20) not null",
    "password varchar(300) not null",
    "email varchar(254) not null",
    "creation timestamp not null default (DATETIME('now'))",
    "salt varbin(128) not null",
    "status varchar(30) not null",
    "lastOnline timestamp not null default (DATETIME('now'))",
    "previousVisitAt timestamp not null default (DATETIME('now'))",
    "isDeleted boolean not null default 0",
    "needsPasswordReset boolean not null default 0"
  )


  result.exec sql"create unique index UserNameIx on person (name);"
  result.exec sql"create index PersonStatusIdx on person(status);"

  # -- Post

  result.createTable(
    "post",
    "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids not integer
    "author varchar(64) not null", # Difference: We use varchar(64) for ids not integer.
    "ip inet not null",
    "content varchar(1000) not null",
    "thread varchar(64) not null", # Difference: We use varchar(64) for ids not integer.
    "creation timestamp not null default (DATETIME('now'))",
    "isDeleted boolean not null default 0",
    "replyingTo varchar(64)", # Difference: We use varchar(64) for ids not integer.
    "foreign key (thread) references thread(id)",
    "foreign key (author) references person(id)",
    "foreign key (replyingTo) references post(id)"
  )

  result.exec sql"create index PostByAuthorIdx on post(thread, author);"

  result.createTable(
    "postRevision",
    "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids not integer
    "creation timestamp not null default (DATETIME('now'))",
    "original varchar(64) not null", # Difference: We use varchar(64) for ids not integer.
    "content varchar(1000) not null",
    "foreign key (original) references post(id)"
  )

  # -- Session
  result.createTable(
    "session",
    "id varchar(64) primary key", # Difference: We use varchar(64) for ids not integer.
    "ip inet not null",
    "key varchar(300) not null",
    "userid varchar(64) not null", # Difference: We use varchar(64) for ids not integer.
    "lastModified timestamp not null default (DATETIME('now'))",
    "foreign key (userid) references person(id)"
  )

  # -- Likes
  result.createTable(
    "like",
    "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids, not integer.
    "author varchar(64) not null", # Difference: We use varchar(64) for ids, not integer.
    "post varchar(64) not null", # Difference: We use varchar(64) for ids, not integer.
    "creation timestamp not null default (DATETIME('now'))",
    "foreign key (author) references person(id)",
    "foreign key (post) references post(id)"
  )

  # -- Report
  result.createTable(
    "report",
    "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids, not integer.
    "author varchar(64) not null", # Difference: We use varchar(64) for ids, not integer.
    "post varchar(64) not null",
    "kind varchar(30) not null",
    "content varchar(500) not null default ''",
    "foreign key (author) references person(id)",
    "foreign key (post) references post(id)",
  )

  # -- FTS
  if not result.createVirtualTable(
    "thread_fts USING fts4", 
    "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids, not integer.
    "name varchar(100) not null"):
      echo "Failed to create thread_fts4 table: fts4 not supported"
  else:
    result.exec(sql"""
      INSERT INTO thread_fts
      SELECT id, name FROM thread;
    """, [])
  
  if not result.createVirtualTable(
    "post_fts USING fts4",
    "id varchar(64) primary key not null", # Difference: We use varchar(64) for ids, not integer.
    "content varchar(1000) not null,"):
      echo "Failed to create post_fts4 table: fts4 not supported"
  else:
    result.exec(sql"""
      INSERT INTO post_fts
      SELECT id, content FROM post;
    """, [])

  return result