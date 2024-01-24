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
  