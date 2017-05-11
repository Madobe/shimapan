[![Code Climate](https://codeclimate.com/github/Madobe/shimapan/badges/gpa.svg)](https://codeclimate.com/github/Madobe/shimapan)
[![Inline docs](http://inch-ci.org/github/Madobe/shimapan.svg?branch=master)](http://inch-ci.org/github/Madobe/shimapan)

# Shimapan

Invite link: https://discordapp.com/oauth2/authorize?&client_id=293636546211610625&scope=bot&permissions=268446726

## Overview

Aramis Clan Discord bot. Has the following functionality:

* Moderation commands (mute, punish, kick, ban)
* Custom commands
* Activity logging

_NOTE: This bot is meant to run on UNIX-like systems and no instructions will be provided for 
Windows installation though it will still run if you set it up properly._

## Dependencies

This bot is made to run on MRI Ruby 2.4.0. I have not tested it on any other versions.

## Installation

Run the bundler to install all gems and dependencies.

    bundle install

Some of the gems may require you to install additional libraries. The instructions for all of these
are on the relevant gem's documentation.

If you don't have Bundler, just install it via:

    gem install bundler

The file `lib/config/connect.yml` must be updated with the correct values to use the bot. For
example:

    client_id: 000000000000000000
    token: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'

The client ID and token will both be available from your My Apps section on Discord's Developer
site.

Database connectivity is set up in `lib/config/database.yml`. If `rake db:create` cannot make your
database, you will have to grant permissions to the user for the relevant database (by ENV).

After all of the above is complete, just run this in the terminal:

    rake shimapan:run

You can specify the environment after the run (`rake shimapan:run:production`).

Note that if you run the bot like this, it will die if you Ctrl + C or close the shell. Adding an 
ampersand (&) after the command will allow you to close the shell but the bot will still die if your 
computer disconnects from the internet (also works like this if you had started it on a remote 
server). To avoid this, use `nohup` or `screen` to disconnect the instance from your shell user.


     nohup rake shimapan:run:production > /dev/null 2>&1&

## Documentation

All documentation for the bot can be found [in the Wiki](https://github.com/Madobe/shimapan/wiki).
Alternatively, look at the [Rubydoc](http://www.rubydoc.info/github/Madobe/shimapan/master).

## License

Copyright (c) 2017. Distributed under the MIT License. See [LICENSE](LICENSE) for more details.
