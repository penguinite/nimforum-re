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
  for i in 0..20 - len(name):
    spaces.add(" ")
  return "$#$#-- $#" % [name, spaces, desc]
  
const helpPromptA = @[
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
  genCommand("--dev", "Creates a developmental setup"),
  genCommand("--blank", "Creates a blank setup"),
  genCommand("--test", "Does the same thing as the --dev command"),
  genCommand("--setup", "Does the same thing as the setup command")
]

proc helpPrompt*(): string = 
  result = helpPromptA.join("\n")

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
    recaptcha=("", "", false),
    smtp=("", "", "", "", false, false),
    isDev=true,
    "nimforum-dev.db",
    ga = ("", false)
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
  let
    password = makeId(64)
    result = db.createUserRaw(newUser("admin", password, "admin@localhost.local", Admin))
  if result  == "":
    echo "Username: \"admin\""
    echo "Email: \"admin@localhost.local\""
    echo "Password: \"", password, "\""
  else:
    echo "Failed to create user: ", result
  
  echo "Development forum setup complete!"

proc friendlySetup*() = 
  echo("""
Welcome to the NimForum setup script. Please answer the following questions.
These can be changed later in the generated forum.ini file.
  """)

  let
    name = question("Forum full name", "Nim forum")
    title = question("Forum short name", "Nim forum")
    hostname = question("Forum hostname", "forum.nim-lang.org")
    
  echo """
nimforum-re supports recaptcha as an optional feature.
If you would like to enable recaptcha then answer yes
"""
  var
    recaptchaSiteKey, recaptchaSecretKey = ""
    recaptchaEnabled = false
  if questionBool("Enable recaptcha?", false):
    echo("\nThe following question are related to recaptcha.")
    echo("You must setup recaptcha v2 for your forum (Here: https://www.google.com/recaptcha/admin)")
    echo("And then supply the site key and secret key, please do so now before answering.")
    recaptchaSiteKey = question("Recaptcha site key: ")
    recaptchaSecretKey = question("Recaptcha secret key: ")
    recaptchaEnabled = true


  echo """
nimforum-re supports sending email via SMTP for email verification.
If you'd like to enable that then answer yes to this question
and be prepared to fill out the rest of the SMTP details.
"""

  var
    smtpAddress, smtpUser, smtpPassword, smtpFromAddr = ""
    smtpTls, smtpEnabled = false
  if questionBool("Enable smtp?", false):
    smtpAddress = question("SMTP address", "mail.hostname.com")
    smtpUser = question("SMTP user")
    smtpPassword = question("SMTP password")
    smtpFromAddr = question("SMTP email sender address", "mail@mail.hostname.com")
    smtpTls = questionBool("Enable TLS for SMTP", true)
    smtpEnabled = true

  echo """
nimforum-re supports Google Analytics for collecting data, this is an optional feature.
Please beware of any legal considerations when adding Google Analytics to your forum.
You will have to add a clause in your privacy policy if you decide to add this.
  """
  
  var
    analyticsEnabled = false
    analyticsID = ""
  if questionBool("Enable Google Analytics for your forum?", false):
    analyticsID = question("Google Analytics ID (e.g UA-12345678-1)")
    analyticsEnabled = true

  let dbPath = question("Database path", "nimforum.db")
  initialiseConfig(
    name, title, hostname, (recaptchaSiteKey, recaptchaSecretKey, recaptchaEnabled),
    (smtpAddress, smtpUser, smtpPassword, smtpFromAddr, smtpTls, smtpEnabled), isDev=false,
    dbPath, (analyticsID, analyticsEnabled)
  )

  var db = setup(dbPath)

  echo "Would you like to add an administrator account?"
  echo "You can always add one later if you'd like"
  if questionBool("Add admin account", true):
    let
      password = makeId(64)
      adminUser = question("Admin username", "admin")
      adminEmail = question("Admin email")
    
    echo "Adding an admin user"
    let result = db.createUserRaw(newUser(adminUser,password,adminEmail,Admin))
    if result == "":
      echo "Username: \"", adminUser, "\""
      echo "Email: \"", adminEmail, "\""
      echo "Password: \"", password, "\""
    else:
      echo "Failed to create user: ", result

  echo("Setup complete!")