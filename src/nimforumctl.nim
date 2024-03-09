## A potholectl-like (which in turn, I think is inspired by pleromactl) command for nimforum.
import std/[os, strutils, parseopt, tables]
import ctlcommon
import core/[database]

if paramCount() == 0:
  echo helpPrompt
  
var
  command = ""
  p = initOptParser()
  args: Table[string, string] = initTable[string,string]()

for kind, key, val in p.getopt():
  case kind
  of cmdLongOption, cmdShortOption, cmdArgument:
    if len(command) == 0:
      command = key
      continue

    if len(val) > 0:
      args[key] = val
    else:
      args[key] = ""
  of cmdEnd: break

if args.check("v","version") or args.check("h", "help"):
  echo helpPrompt
  quit(0)

case command:
of "setup", "--setup":
  # Check for developmental setup
  if args.check("d","dev"):
    setupDevMode()
    quit(0)

  # Check for blank setup
  if args.check("b","blank"):
    discard database.setup("nimforum-blank.db")
    quit(0)

  # Finally, do the real, friendly setup procedure.

of "--dev","--test": setupDevMode()
of "--blank": discard database.setup("nimforum-blank.db")
else:
  echo helpPrompt
  echo "Unknown command: ", command