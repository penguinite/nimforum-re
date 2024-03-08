## A potholectl-like (which in turn, I think is inspired by pleromactl) command for nimforum.
import std/[os, strutils, parseopt]
import ctlcommon

if paramCount() == 0:
  echo helpPrompt
  
var
  p = initOptParser()
  args: Table[string, string] = initTable[string,string]()

for kind, key, val in p.getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    if len(val) > 0:
      args[key] = val
    else:
      args[key] = ""
  of cmdEnd: break

if args.check("v","version") or args.check("h", "help"):
  echo helpPrompt
  quit(0)

case paramStr(1):
of "setup", "--setup":
  # Check for developmental setup
  if args.check("d","dev"):
    quit(0)

  # Check for blank setup
  if args.check("b","blank"):
    quit(0)

  # Finally, do the real, friendly setup procedure.

of "--dev","--test":
  initialiseConfig(
    "Development Forum",
    "Development Forum",
    "localhost",
    recaptcha=("", ""),
    smtp=("", "", "", "", false),
    isDev=true,
    dbPath
  )

  initialiseDb(
    admin=("admin", "admin", "admin@localhost.local"),
    dbPath
  )
of "--blank":
  let dbPath = "nimforum-blank.db"
  initialiseDb(
    admin=("", "", ""),
    dbPath
  )

else:
  echo helpPrompt
  echo "Unknown command: " & paramStr(1)