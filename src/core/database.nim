import db_connector/db_sqlite
from config import Config

proc init*(config: Config): DbConn =
  return open(connection=config.dbPath, user="", password="", database="nimforum")