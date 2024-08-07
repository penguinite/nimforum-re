
# Package
version       = "2.3.0"
author        = "Dominik Picheta"
description   = "The Nim forum (re-written, to be better.)"
license       = "MIT"
srcDir = "src"
binDir = "build"
bin = @["nimforum","nimforumctl"]

skipExt = @["nim"]

# Dependencies

requires "nim >= 2.0.0"
requires "bcrypt"
requires "hmac"
requires "recaptcha"

requires "prologue"

requires "iniplus >= 0.2.0"
requires "db_connector >= 0.1.0"
requires "smtp >= 0.1.0"
requires "checksums"

proc checkForBuild() =
  if not dirExists("build"):
    exec "nimble build"

task debug, "Creates a debug build":
  for binary in bin:
    exec "nimble build " & binary & " -d:debug --stackTrace:on --parallelBuild:0 --lineDir:on --lineTrace:on --checks:on --debuginfo:on --debugger:native"

task release, "Creates a release build":
  for binary in bin:
    exec "nimble build " & binary & " -d:release -d:danger --checks:off --stackTrace:on --parallelBuild:0 --opt:speed"

task devdb, "Creates a test DB (with admin account!)":
  checkForBuild()
  exec "./build/nimforumctl setup -d"

task blankdb, "Creates a blank DB":
  checkForBuild()
  exec "./build/nimforumctl setup -b"

task backend, "Runs the backend":
  checkForBuild()
  exec "./build/nimforum"