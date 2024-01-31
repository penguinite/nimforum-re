
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

  UserObj* = object of RootObj
    id*, name*, pass*, email*: string
    rank: UserRank
  
  User* = ref object of UserObj
    
  SessionObj* = object of UserObj
    previousVisitAt: int
  Session* = ref object of SessionObj

proc clear*(s: var SessionObj) = s = SessionObj()
proc clear*(s: var Session) = s = Session()
proc clear*(s: SessionObj): SessionObj = return result
proc clear*(s: Session): Session = return result
proc isLoggedIn*(s: SessionObj): bool = return s.name.len() != 0
proc isLoggedIn*(s: Session): bool = return isLoggedIn(s[])