# Package
version       = "2.3.0"
author        = "Dominik Picheta"
description   = "The Nim forum"
license       = "MIT"

srcDir = "src"

bin = @["forum"]

skipExt = @["nim"]

# Dependencies

requires "nim >= 1.0.6"
requires "httpbeast >= 0.4.0"
requires "jester"
requires "bcrypt"
requires "hmac"
requires "recaptcha"
requires "sass"

requires "karax"

requires "iniplus >= 0.2.0"
requires "webdriver"
  requires "db_connector >= 0.1.0"
  requires "smtp >= 0.1.0"
  requires "checksums"

# Tasks

task backend, "Compiles and runs the forum backend":
  exec "nimble c src/forum.nim"
  exec "./src/forum"

task runbackend, "Runs the forum backend":
  exec "./src/forum"

task testbackend, "Runs the forum backend in test mode":
  exec "nimble c -r -d:skipRateLimitCheck src/forum.nim"

task testdb, "Creates a test DB (with admin account!)":
  exec "nimble c src/setup_nimforum"
  exec "./src/setup_nimforum --test"

task devdb, "Creates a test DB (with admin account!)":
  exec "nimble c src/setup_nimforum"
  exec "./src/setup_nimforum --dev"

task blankdb, "Creates a blank DB":
  exec "nimble c src/setup_nimforum"
  exec "./src/setup_nimforum --blank"

task test, "Runs tester":
  exec "nimble c -y --mm:refc src/forum.nim"
  exec "nimble c -y -r -d:actionDelayMs=0 tests/browsertester"

task fasttest, "Runs tester without recompiling backend":
  exec "nimble c -r -d:actionDelayMs=0 tests/browsertester"
