# nimforum-re

*Note:* This is a heavily-modified fork of nimforum. It is not compatible with the upstream nimforum whatsoever.

nimforum-re is a lightweight forum implementation with many similarities to Discourse.
It is implemented in the [Nim](https://nim-lang.org) programming language and uses SQLite for its database.

## Differences to vanilla nimforum

1. This uses an INI-style configuration format provided by [iniplus](https://github.com/penguinite/iniplus.git)
2. This has a **lot** less warnings when building.
3. This tries to use the latest dependencies whenever available.

## Examples in the wild

None, but if you're looking for examples of vanilla nimforum in the wild then there's only one! [nim-lang forum!](https://forum.nim-lang.org)

## Features

None!

Right now, the codebase is being completely rewritten, and so it's very, very early in development.
This is what we have achieved with this fork:

* A complete re-write of setup_nimforum, with the goal for it to be similar to pleromactl (A general purpose server maintenance tool)

And here is a list of every single feature we'd like to complete:
* Every single nimforum feature. nimforum-re should be an extended version of nimforum, not a more limited one.
* Custom avatar support whilst preserving gravatar
* Support for libravatar (Including custom instances)
* Image attachments (Either via [https://forum.nim-lang.org/t/8694#56729](S3) or flat files.)

Note that the above list is not a complete list, and some things might change as the fork evolves.

## Setup

[See this document.](https://github.com/nim-lang/nimforum/blob/master/setup.md)

## Dependencies

The following lists the dependencies which you may need to install manually
in order to get NimForum running, compiled*, or tested†.

* SQLite $
* Nim (and the Nimble package manager) \*

[*] Build-time dependencies
[$] Run-time dependencies


## Development

Check out the tasks defined by this project's ``nimforum.nimble`` file by
running ``nimble tasks``, as of writing they are:

```
devdb                Creates a test DB (with admin account!)
blankdb              Creates a blank DB
```

## Quickstart

To get up and running quickly, run the following commands: (Assuming you have every essential dependency installed)

```bash
# Clone the git repository
git clone https://github.com/penguinite/nimforum-re && cd nimforum-re

# Build nimforum-re with release settings
nimble -d:release build

# Setup the db with an administrator account!
# Don't worry, login details are printed.
nimble devdb

# Run the nimforum backend
nimble backend
```

Development typically involves running `nimble devdb` to create a developmental setup.
And then running `nimble run nimforum` whenever you make a change.
Yes, recompilation is sadly neccessary for every change.

### With docker

You can easily launch site on localhost if you have `docker` and `docker-compose`.
You don't have to setup dependencies (libsass, sglite, pcre, etc...) on your host PC.

Note: This method has been untested as I am busy working on more important stuff.

To get up and running:

```bash
cd docker
docker-compose build
docker-compose up
```

And you can access local NimForum site, open [http://localhost:5000](http://localhost:5000) .

# Copyright

Copyright (c) 2012-2018 Andreas Rumpf, Dominik Picheta. All Rights Reserved.
Copyright (c) 2023-2024 penguinite <penguinite@tuta.io>

nimforum-re is licensed under the MIT license.