import recaptcha, std/asyncdispatch
from configs import Config

type
  Captcha* = object of RootObj
    loaded*: bool
    recaptcha*: ReCaptcha

proc isNil*(c: Captcha): bool = return not c.loaded

proc hasCaptchaKeys*(c: Config): bool = return len(c.recaptchaSecretKey) > 0 and len(c.recaptchaSiteKey) > 0

proc init*(c: Config): Captcha =
  result.recaptcha = initReCaptcha(c.recaptchaSecretKey, c.recaptchaSiteKey)
  result.loaded = true
  return result

proc validateCaptcha*(config: Config, captcha: Captcha, recaptchaResp, ip: string): bool =
  # captcha validation:
  if config.recaptchaSecretKey.len() <= 0 and captcha.recaptcha.verify(recaptchaResp, ip).failed:
    return false
  return true  