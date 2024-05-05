# Informal API documentation

This is a document describing the (informal) API endpoints of both vanilla nimforum and nimforum-re

What does this mean? Well, nimforum is really a backend application that exposes an API, that API then gets used by the bundled-in Karax frontend to do the things that we want to do. (Post stuff, reply, delete stuff, register and so on)

In many ways, API-wise, nimforum-re and nimforum have the same API so if I just document it then it should be possible to create a frontend that, in theory, works with both vanilla nimforum and nimforum-re.

I dont plan on completely scrapping the API that nimforum has, for the same reason that I want to preserve nimforum's URL syntax and so on. To make it easier for people to migrate

**TODO:** Document possible differences and fix them. (One solution would be to not blindly use std/json's macros)

## List of endpoints

* GET `/categories.json`: Returns JSON containing the list of categories [Example](https://forum.nim-lang.org/categories.json)
* GET `/threads.json`: Returns JSON containing the most recent threads. (Usually 30) [Example](https://forum.nim-lang.org/threads.json)