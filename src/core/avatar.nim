import std/strutils, checksums/md5

proc getGravatarUrl*(email: string, size = 80): string =
  let emailMD5 = email.toLowerAscii.toMD5
  return ("https://www.gravatar.com/avatar/" & $emailMD5 & "?s=" & $size &
     "&d=identicon")