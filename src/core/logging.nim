import std/[times, strutils]
## A very simple logger that doesn't depend on weird types or whatever.
## Thanks to: https://hookrace.net/blog/writing-an-async-logger-in-nim/

# A simple logger for custom levels.
template log*(level: string, msg: varargs[string,`$`]) =
  let info = instantiationInfo()
  echo "[$# $#] ($#:$#) [$#]: $#" % [getDateStr(), getClockStr(), info.filename, $info.line, level, msg.join]

# Error is used whenever there is a flaw that needs addressing
# And this causes the app to exit too.
template error*(msg: varargs[string, `$`]) =
  log("Error", msg)
  quit(1)

# Warn is used whenever there is a flaw that needs addressing but that we can ignore for now.
# Ie. maybe it's an error where some setting needs to be set, but there is a default value.
template warn*(msg: varargs[string, `$`]) = log("Warning", msg)

# Info is used for the same purpose, to indicate a potential change of plans but
# where there is no need to address.
template info*(msg: varargs[string, `$`]) = log("Info", msg)

# Debug is used to log helpful debugging info.
when defined(debug):
  template debug*(msg: varargs[string, `$`]) = log("Debug", msg)
else:
  template debug*(msg: varargs[string, `$`]) = discard