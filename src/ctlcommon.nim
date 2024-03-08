
## This module contains procedures used by nimforumctl
proc question*(q: string): string =
  while result.len == 0:
    stdout.write(q)
    result = stdin.readLine()

proc genCommand*(name, desc: string): string =
  var spaces = ""
  for i in 0..80 - len(name):
    spaces.add(" ")
  return "$#$#-- $#" % [name, spaces, desc]
  
const helpPrompt* = @[
  "nimforumctl",
  "",
  "Commands:",
  genCommand("setup","An interactive step-by-step setup prompt. Ideal for new installations."),
  "Arguments for setup:",
  genCommand("-d, --dev", "Creates a developmental setup"),
  genCommand("-b, --blank", "Creates a blank setup"),
  "",
  "Please do not use the following commands, they are only here for backwards compatability with the old setup_nimforum commands.",
  "Legacy Commands:",
  genCommand("--dev", "Does the same thing as the devSetup command"),
  genCommand("--blank", "Creates a completely blank setup"),
  genCommand("--test", "Does the same thing as the --dev command"),
  genCommand("--setup", "Does the same thing as the setup command")
]

proc check*(table: Table[string, string], long, short: string): bool =
  ## Checks if a long or short key exists in a table.
  for val in table.keys:
    if long == val or short == val:
      return true
  return false