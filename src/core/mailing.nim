import std/[asyncdispatch, strutils, times, tables, logging, uri]
import smtp

import configs, auth

type
  Mailer* = object
    loaded: bool
    lastReset: Time
    emailsSent: CountTable[string]

proc newMailer*(config: Config): Mailer =
  result.loaded = true
  result.lastReset = getTime()
  result.emailsSent = initCountTable[string]()

proc isNil*(m: Mailer): bool =
  return not m.loaded

proc rateCheck(mailer: var Mailer, address: string): bool =
  ## Returns true if we've emailed the address too much.
  let diff = getTime() - mailer.lastReset
  if diff.inHours >= 1:
    mailer.lastReset = getTime()
    mailer.emailsSent.clear()

  result = address in mailer.emailsSent and mailer.emailsSent[address] >= 2
  mailer.emailsSent.inc(address)

proc sendMail*(
  config: Config,
  mailer: var Mailer,
  subject, message, recipient: string,
  otherHeaders:seq[(string, string)] = @[]
) {.async.} =
  # Ensure we aren't emailing this address too much.
  if rateCheck(mailer, recipient):
    warn "Too many messages have been sent to this email address recently: ", recipient

  if config.smtpAddress.len == 0:
    warn "Cannot send mail: no smtp server configured (smtpAddress)."
    return
  if config.smtpFromAddr.len == 0:
    warn "Cannot send mail: no smtp from address configured (smtpFromAddr)." 
    return

  var client: AsyncSmtp
  if config.smtpTls:
    client = newAsyncSmtp(useSsl=false)
    await client.connect(config.smtpAddress, Port(config.smtpPort))
    await client.startTls()
  elif config.smtpSsl:
    client = newAsyncSmtp(useSsl=true)
    await client.connect(config.smtpAddress, Port(config.smtpPort))
  else:
    client = newAsyncSmtp(useSsl=false)
    await client.connect(config.smtpAddress, Port(config.smtpPort))

  if config.smtpUser.len > 0:
    await client.auth(config.smtpUser, config.smtpPassword)

  let toList = @[recipient]

  var headers = otherHeaders
  headers.add(("From", config.smtpFromAddr))

  let dateHeader = now().utc().format("ddd, dd MMM yyyy hh:mm:ss") & " +0000"
  headers.add(("Date", dateHeader))

  let encoded = createMessage(subject, message,
      toList, @[], headers)

  await client.sendMail(config.smtpFromAddr, toList, $encoded)

proc sendPassReset(config: Config, mailer: var Mailer, email, user, resetUrl: string) {.async.} =
  let message = """Hello $1,
A password reset has been requested for your account on the $3.

If you did not make this request, you can safely ignore this email.
A password reset request can be made by anyone, and it does not indicate
that your account is in any danger of being accessed by someone else.

If you do actually want to reset your password, visit this link:

  $2

Thank you for being a part of our community!
""" % [user, resetUrl, config.name]

  let subject = config.name & " Password Recovery"
  await sendMail(config, mailer, subject, message, email)

proc sendEmailActivation(
  config: Config, mailer: var Mailer,
  email, user, activateUrl: string
) {.async.} =
  let message = """Hello $1,
You have recently registered an account on the $3.

As the final step in your registration, we require that you confirm your email
via the following link:

  $2

Thank you for registering and becoming a part of our community!
""" % [user, activateUrl, config.name]
  let subject = config.name & " Account Email Confirmation"
  await sendMail(config, mailer, subject, message, email)

type
  SecureEmailKind* = enum
    ActivateEmail, ResetPassword

proc sendSecureEmail*(
  config: Config, mailer: var Mailer,
  kind: SecureEmailKind,
  hostname, name, password, email, salt: string
) {.async.} =
  let epoch = int(epochTime())

  let path =
    case kind
    of ActivateEmail:
      "activateEmail"
    of ResetPassword:
      "resetPassword"
  
  let url = "https://$#/$#?nick=$#&epoch=$#&ident=$#" %
      [
        hostname,
        path,
        encodeUrl(name),
        encodeUrl($epoch),
        encodeUrl(makeIdentHash(name, password, epoch, salt))
      ]

  debug(url)

  let emailSentFut =
    case kind
    of ActivateEmail:
      sendEmailActivation(config, mailer, email, name, url)
    of ResetPassword:
      sendPassReset(config, mailer, email, name, url)
  yield emailSentFut
  if emailSentFut.failed:
    warn("Couldn't send email: ", emailSentFut.error.msg)
    #if emailSentFut.error of ForumError:
    #  raise emailSentFut.error
    #else:
    #  raise newForumError("Couldn't send email", @["email"])
