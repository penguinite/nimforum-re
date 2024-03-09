#
#
#              The Nim Forum
#        (c) Copyright 2018 Andreas Rumpf, Dominik Picheta
#        Look at license.txt for more info.
#        All rights reserved.
#
# Script to initialise the nimforum.

import strutils, os, times, options, terminal, iniplus

when NimMajor > 1:
  import db_connector/db_sqlite
else:
  import std/db_sqlite

import auth, frontend/user

proc createUser(db: DbConn, user: tuple[username, password, email: string],
                rank: Rank) =
  assert user.username.len != 0
  let salt = makeSalt()
  let password = makePassword(user.password, salt)

  exec(db, sql"""
    INSERT INTO person(name, password, email, salt, status, lastOnline)
    VALUES (?, ?, ?, ?, ?, DATETIME('now'))
  """, user.username, password, user.email, salt, $rank)

proc setup() =
  

proc echoHelp() =
    quit("""
Usage: setup_nimforum opts

Options:
  --setup         Performs first time setup for end users.

Development options:
  --dev           Creates a new development DB and config.
  --test          Creates a new test DB and config.
  --blank         Creates a new blank DB.
  """)

when isMainModule:
  if paramCount() > 0:
    case paramStr(1)
    of "--dev":
  
    of "--test":
      
      echo("Initialising nimforum for testing...")
      initialiseConfig(
        "Test Forum",
        "Test Forum",
        "localhost",
        recaptcha=("", ""),
        smtp=("", "", "", "", false),
        isDev=true,
        dbPath
      )

      
    of "--blank":
      
      echo("Initialising blank DB...")
      
    of "--setup":
      setup()
    else:
      echoHelp()
  else:
    echoHelp()

  quit()
