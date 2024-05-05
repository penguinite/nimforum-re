import core/[database, configs, mailing, captchawrap]

import prologue, db_connector/db_sqlite

echo "nimforum"

var
  db{.threadvar.}: DbConn
  config{.threadvar.}: configs.Config
  mailer{.threadvar.}: Mailer
  captcha{.threadvar.}: Captcha

proc init() =
  ## Reloads every thread-local variable, meant to be executed every page visit.
  if config.isNil(): config = configs.init()
  if db.isNil(): db = database.init(config)
  if captcha.isNil() and config.hasCaptchaKeys(): captcha = captchawrap.init(config)
  if mailer.isNil(): mailer = newMailer(config)

init() # Run at least once on startup.

# Maybe move this into its own separate file when it gets too big
proc getCategoriesJson(ctx: Context) {.async.} =
  ## Returns JSON containing the categories used for this forum
  # TODO: Limit this query in the case of many many categories
  init()
  resp jsonResponse(%getCategories(db))

proc getThreadsJson(ctx: Context) {.async.} =
  ## Returns JSON containing the most recent threads.
  #
  init()

let app = newApp(
  newSettings(
    debug = defined(debug),
    port = Port(config.port),
    appName = "nimforum"
  )
)

echo "Running on port ", config.port
app.get("/categories.json", getCategoriesJson)
app.get("/threads.json", getThreadsJson)
app.run()