import std/[strutils, tables]
import core/[configs, database, user, auth]

## This module contains procedures used by nimforumctl
proc question*(question: string): string =
  stdout.write question, ": "
  return stdin.readLine()

proc question*(question: string, default: string): string =
  stdout.write question, " [", default, "]: "
  result = stdin.readLine()
  if result == "":
    return default
  else:
    return result

proc questionBool*(question: string): bool =
  stdout.write question, ": "
  return stdin.readLine().parseBool()

proc questionBool*(question: string, default: bool): bool =
  stdout.write question, " [", default, "]: "
  let tmp = stdin.readLine()
  if tmp == "":
    return default
  else:
    return tmp.parseBool()


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

proc setupDevMode*() = 
  echo "Initializing configuration"
  initialiseConfig(
    "Development Forum",
    "Development Forum",
    "localhost",
    recaptcha=("", ""),
    smtp=("", "", "", "", false),
    isDev=true,
    "nimforum-dev.db"
  )

  echo "Initializing database"
  var db = setup("nimforum-dev.db")

  echo "Creating test data for development"
  for rank in Spammer..Moderator:
    discard db.createUser(
      newUser(
        toLowerAscii($rank),
        toLowerAscii($rank),
        toLowerAscii($rank) & "@localhost.local",
        rank
      )
    )

  echo "Creating categories for fun"
  for category in @[
    ("Libraries", "Libraries and library development", "0198E1"),
    ("Announcements", "Announcements by Nim core devs", "FFEB3B"),
    ("Fun", "Posts that are just for fun", "00897B"),
    ("Potential Issues", "Potential Nim compiler issues", "E53935")
  ]:
    if db.createCategory(category[0], category[1], category[2]) == false:
      echo "Failed to create category \"", category[0], "\""


  echo "Adding an admin user"
  let password = makeId(64)
  if db.createUser(newUser("admin", password, "admin@localhost.local", Admin)):
    echo "Username: \"admin\""
    echo "Email: \"admin@localhost.local\""
    echo "Password: \"", password, "\""
  else:
    echo "Failed to create user."
  
  echo "Development forum setup complete!"

proc friendlySetup*() = 
  echo("""
Welcome to the NimForum setup script. Please answer the following questions.
These can be changed later in the generated forum.ini file.
  """)

  let name = question("Forum full name[fx. \"Nim forum\"]: ", "Nim forum")
  let title = question("Forum short name[]: ")

  let hostname = question("Forum hostname: ")

  let adminUser = question("Admin username: ")
  let adminEmail = question("Admin email: ")

  echo("")
  echo("The following question are related to recaptcha. \nYou must set up a " &
       "recaptcha v2 for your forum before answering them. \nPlease do so now " &
       "and then answer these questions: https://www.google.com/recaptcha/admin")
  let recaptchaSiteKey = question("Recaptcha site key: ")
  let recaptchaSecretKey = question("Recaptcha secret key: ")


  echo("The following questions are related to smtp. You must set up a \n" &
       "mailing server for your forum or use an external service.")
  let smtpAddress = question("SMTP address (eg: mail.hostname.com): ")
  let smtpUser = question("SMTP user: ")
  let smtpPassword = question()
  let smtpFromAddr = question("SMTP sending email address (eg: mail@mail.hostname.com): ")
  let smtpTls = parseBool(question("Enable TLS for SMTP: "))

  echo("The following is optional. You can specify your Google Analytics ID " &
       "if you wish. Otherwise just leave it blank.")
  stdout.write("Google Analytics (eg: UA-12345678-1): ")
  let ga = stdin.readLine().strip()

  let dbPath = "nimforum.db"
  initialiseConfig(
    name, title, hostname, (recaptchaSiteKey, recaptchaSecretKey),
    (smtpAddress, smtpUser, smtpPassword, smtpFromAddr, smtpTls), isDev=false,
    dbPath, ga
  )

  initialiseDb(
    admin=(adminUser, adminPass, adminEmail),
    dbPath
  )

  echo("Setup complete!")