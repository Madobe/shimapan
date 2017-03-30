[![Code Climate](https://codeclimate.com/github/Madobe/shimapan/badges/gpa.svg)](https://codeclimate.com/github/Madobe/shimapan)
[![Inline docs](http://inch-ci.org/github/Madobe/shimapan.svg?branch=master)](http://inch-ci.org/github/Madobe/shimapan)

# Shimapan
Aramis Clan Discord bot. Has the following functionality:

* Moderation commands (mute, punish, kick, ban)
* Custom commands
* Activity logging

_NOTE: This bot is meant to run on UNIX-like systems and no instructions will be provided for 
Windows installation though it will still run if you set it up properly._

## Dependencies

The following gems are required to run this bot:

* [discordrb](https://github.com/meew0/discordrb)
* [mysql2](https://github.com/brianmario/mysql2)
* [activesupport](http://www.rubydoc.info/gems/activesupport/4.2.6)

You can just run this command to do that, assuming you have all the dependencies for each of those
gems:

    gem install discordrb mysql2 activesupport

## Installation

The file `lib/config/connect.yaml` must be updated with the correct values to use the bot. For
example:

    client_id: 000000000000000000
    token: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    invite_link: "https://discordapp.com/oauth2/authorize?client_id=293636546211610625&scope=bot&permissions=285223953"

The client ID and token will both be available from your My Apps section on Discord's Developer
site.

The bot assumes you will be using a MySQL database with the user `shimapan@localhost`. You can run
the following commands to ready up the database for Shimapan:

    CREATE DATABASE shimapan CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER shimapan;
    GRANT ALL PRIVILEGES ON shimapan.* TO shimapan@localhost;

If you wish to change the password associated with the `shimapan@localhost` user, go to
[database.rb](lib/database.rb) and change the SQL connection to this:

    @@db = Mysql2::Client.new(
      host:      "localhost",
      username:  "shimapan",
      password:  "YOUR PASSWORD HERE",
      database:  "shimapan",
      encoding:  "utf8mb4",
      reconnect: true
    )

## Documentation

All documentation for the bot can be found [in the Wiki](https://github.com/Madobe/shimapan/wiki).
Alternatively, look at the [Rubydoc](http://www.rubydoc.info/github/Madobe/shimapan/master).

## License

Copyright (c) 2017. Distributed under the MIT License. See [LICENSE](LICENSE) for more details.
