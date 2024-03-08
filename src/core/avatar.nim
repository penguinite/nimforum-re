import std/strutils, checksums/md5

proc getGravatarUrl*(email: string, size = 80): string =
  return "https://www.gravatar.com/avatar/" & $email.toLowerAscii.toMD5 & "?s=" & $size & "&d=identicon"