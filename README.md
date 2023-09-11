# defaultism
This repo is just a couple of frequently used and helpful tools that I've collected or developed over the years.

Right now, it's pretty sparse for 2 files:
* `datecheck` written to display simple information to the screen every 3 seconds. Originally written to defeat SSH timeout sessions.
* `findchildren` find child docker images that use the given imageid as a piece of their base.
* `check_server.sh` show status of users logged into a Valheim Server.

## `datecheck`

Written to display simple information to the screen every 3 seconds.
It was originally written to defeat SSH timeout sessions.
It will take an input, and show the output of _that_ at then end of the spinner.
By default it just shows the output of the `date` command.
You can `CTRL-C` out of it.

## `findchildren`

I used to have plenty of problems with trying to delete images on my local cached "registry", but being blocked because there were "dependent chldren" images.
For a given `imageid` it will loop through all of your image layers to see what depends on that.
It works with `docker` 1.7.1.x and 1.13.1.x also.

## `check_server.pl`

The [lloesche/valheim-server-docker](https://github.com/lloesche/valheim-server-docker) project allows you to run a valheim server on a local machine, in a docker container.
While this is awesome, it might be nice to know who is logged in, and when they logged in/out, and how many people are currently logged in to the server historically (as far as the `docker logs <containerid>` go back) and right now.
This is useful for performing maintenance on the server without disrupting people's ability to enjoy your server.
I wrote this bad perl script to parse certain parts of the logs, and glean that information.
I'm not that happy about the results, but it does work.
