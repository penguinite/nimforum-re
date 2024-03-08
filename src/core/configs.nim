import std/os
import iniplus

type
  Config* = object
    parsed: bool # This exists only for one reason: To check if the config data has actually been parsed into the object.
    smtpTls*, smtpSsl*, isDev*: bool
    smtpAddress*, smtpUser*, smtpPassword*, mlistAddress*, smtpFromAddr*: string
    recaptchaSecretKey*, recaptchaSiteKey*, dbPath*, hostname*, name*, title*, ga*: string
    port*, smtpPort*: int

proc init*(filename: string = getCurrentDir() / "forum.ini"): Config =
  result = Config(smtpAddress: "", smtpPort: 25, smtpUser: "",
                  smtpPassword: "", mlistAddress: "")
  
  let config = parseFile(filename)
  
  result.smtpAddress = config.getStringOrDefault("smtp","address","")
  
  result.smtpPort = 25
  if config.exists("smtp", "port"):
    result.smtpPort = config.getInt("smtp","port")

  result.smtpUser = config.getStringOrDefault("smtp","user","")
  result.smtpPassword = config.getStringOrDefault("smtp","password","")
  result.smtpFromAddr = config.getStringOrDefault("smtp","fromAddr","")

  result.smtpTls = false
  if config.exists("smtp","tls"):
    result.smtpTls = config.getBool("smtp","tls")
  
  result.smtpSsl = false
  if config.exists("smtp","ssl"):
    result.smtpSsl = config.getBool("smtp","ssl")
    
  result.mlistAddress = config.getStringOrDefault("smtp","listAddress","")
  result.recaptchaSecretKey = config.getStringOrDefault("captcha","secretKey","")
  result.recaptchaSiteKey = config.getStringOrDefault("captcha","siteKey","")

  result.isDev = false
  if config.exists("","isDev"):
    result.isDev = config.getBool("","isDev")

  result.dbPath = config.getStringOrDefault("","dbPath","nimforum.db")
  result.hostname = config.getStringOrDefault("web","hostname","")
  result.name = config.getStringOrDefault("web","name","")
  result.title = config.getStringOrDefault("web","title","")
  result.ga = config.getStringOrDefault("web","ga","")

  result.port = 5000
  if config.exists("web","port"):
    result.port = config.getInt("web","port")
  
  result.parsed = true
  return result

proc isNil*(table: Config): bool = return not table.parsed
  
proc initialiseConfig(
  name, title, hostname: string,
  recaptcha: tuple[siteKey, secretKey: string],
  smtp: tuple[address, user, password, fromAddr: string, tls: bool],
  isDev: bool,
  dbPath: string,
  ga: string=""
) =
  let path = getCurrentDir() / "forum.ini"

  var table = newConfigTable()

  # Still quite ugly. We need a load of `condense` everywhere.
  # Ill redo this once I learn macros. But hey! We don't need % anymore!
  # And we don't need JSON too!
  table.setBulkKeys(
    c("", "isDev", isDev),
    c("", "dbPath", dbPath),
    c("web", "name", name),
    c("web", "title", title),
    c("web", "hostname", hostname),
    c("captcha", "siteKey", recaptcha.siteKey),
    c("captcha", "secretKey", recaptcha.secretKey),
    c("smtp", "address", smtp.address),
    c("smtp", "user", smtp.user),
    c("smtp", "password", smtp.password),
    c("smtp", "fromAddr", smtp.fromAddr),
    c("smtp", "tls", smtp.tls)
  )

  if ga.len > 0:
    table.setKey("web","ga", newValue(ga))

  backup(path, some(toString(table)))
  writeFile(path, toString(table))