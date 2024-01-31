import db_connector/db_sqlite
from configs import Config

proc init*(config: Config): DbConn =
  return open(connection=config.dbPath, user="", password="", database="nimforum")

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
  return sql(fields & ") values (" & vals & ")")

proc sqlRead*(table: string, data: varargs[string,`$`]): SqlQuery =
  var statement = "SELECT "
  for i, ch in data:
    if i > 0: statement.add(", ")
    statement.add(ch)
  return sql(statement & " FROM " & table)

proc sqlUpdate*(table: string, data: varargs[string,`$`]): SqlQuery =
  var statement = "UPDATE " & table & " SET "
  for i, ch in data:
    if i > 0: statement.add(", ")
    statement.add(ch)
    statement.add(" = ?")
  return sql(statement & " where id = ?")

proc sqlDelete*(table: string): SqlQuery =
  return sql("DELETE FROM " & table & " WHERE ID = ?")

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