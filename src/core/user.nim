import auth, std/[strutils, times]

# Used to be:
# {'A'..'Z', 'a'..'z', '0'..'9', '_', '\128'..'\255'}
let
  UsernameIdent* = IdentChars + {'-'} # TODO: Double check that everyone follows this.


type
  # Replacement for TForumData
  UserRank* {.pure.} = enum
    Spammer          ## spammer: every post is invisible
    Moderated        ## new member: posts manually reviewed before everybody
                     ## can see them
    Troll            ## troll: cannot write new posts
    Banned           ## A non-specific ban
    EmailUnconfirmed ## member with unconfirmed email address. Their posts
                     ## are visible, but cannot make new posts. This is so that
                     ## when a user with existing posts changes their email,
                     ## their posts don't disappear.
    User             ## Ordinary user
    Moderator        ## Moderator: can change a user's rank
    Admin            ## Admin: can do everything

proc `$`*(rank: UserRank): string =
  case rank:
  of Spammer: return "Spammer"
  of Moderated: return "Moderated"
  of Troll: return "Troll"
  of Banned: return "Banned"
  of EmailUnconfirmed: return "EmailUnconfirmed"
  of User: return "User"
  of Moderator: return "Moderator"
  of Admin: return "Admin"

proc toRank*(rank: string): UserRank = 
  case rank:
  of "Spammer": return Spammer
  of "Moderated": return Moderated
  of "Troll": return Troll
  of "Banned": return Banned
  of "EmailUnconfirmed": return EmailUnconfirmed
  of "User": return User
  of "Moderator": return Moderator
  of "Admin": return Admin
  else:
    return Moderated

type
  UserObj* = object of RootObj
    id*, name*, pass*, email*, salt*: string
    lastOnline*: DateTime
    rank*: UserRank
  
  User* = ref object of UserObj
    
  SessionObj* = object of UserObj
    previousVisitAt: int
  Session* = ref object of SessionObj


proc sanitizeName*(name: string): string =
  for ch in name:
    if ch notin UsernameIdent:
      continue
    result.add(ch)
  
  if len(result) > 20:
    result = result[0..20]

  return result

# We can accomplish these four tasks by just
# running std/strutil's escape() and unescape() procedures.
# So why bother with abstractions?
# Well it might ease the upgrade path if we have to change the logic somehow
proc sanitizePass*(pass: string): string =
  return escape(pass, "","")

proc unsanitizePass*(pass: string): string =
  return unescape(pass, "","")

proc sanitizeEmail*(email: string): string =
  return escape(email, "", "")

proc unsanitizeEmail*(email: string): string =
  return unescape(email, "", "")

proc validateEmail*(email: string): bool =
  ## A very basic email validator.
  # I could do some weird shit like checking the domain name for a valid TLD.
  # Or even worse, checking the domain name for specific email provider.
  # (I am looking at you RobTop, why haven't you added protonmail or tuta to your whitelist already?!?)
  if isEmptyOrWhitespace(email) or len(email) > 254: return false # https://stackoverflow.com/a/574698/492186

  var hasAtSymbol = false
  for ch in email:
    if ch == '@':
      if not hasAtSymbol:
        return false # Return false if we see more than @ symbol
      hasAtSymbol = true
  
  if not hasAtSymbol:
    return false # Return false if we don't see at least one @ symbol

  return true # Everything should be good! sorta...

proc isValid*(user: User): bool =
  if isEmptyOrWhitespace(user.name) or
     isEmptyOrWhitespace(user.email) or
     isEmptyOrWhitespace(user.pass): return false
  return true

proc newUser*(name, pass, email: string, rank: UserRank): User =
  ## Note: This does not do any sanitzation, use sanitizeUser() or newUserSanitized()
  result.name = name
  result.pass = pass
  result.email = email
  result.rank = rank
  result.id = makeId()
  result.salt = makeSalt()

proc sanitizeUser*(user: User): User = 
  result = user
  result.name = sanitizeName(user.name)
  result.email = sanitizeEmail(user.email)
  result.pass = sanitizePass(user.pass)
  return user

proc newUserSanitized*(name, pass, email: string, rank: UserRank): User =
  return newUser(sanitizeName(name), sanitizeEmail(email), sanitizePass(pass), rank)

proc clear*(s: var SessionObj) = s = SessionObj()
proc clear*(s: var Session) = s = Session()
proc clear*(s: SessionObj): SessionObj = return result
proc clear*(s: Session): Session = return result
proc isLoggedIn*(s: SessionObj): bool = return s.name.len() != 0
proc isLoggedIn*(s: Session): bool = return isLoggedIn(s[])