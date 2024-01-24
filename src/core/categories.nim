import std/strutils
import db_connector/db_sqlite

type
  Category* = object of RootObj
    name*, description*, color*: string
    id*, topicsCount*: int

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
        id: data[0].parseInt(),
        name: data[1], description: data[2], color: data[3],
        topicsCount: data[4].parseInt()))
  return result
  