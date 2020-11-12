# defaultism
This repo is just a couple of frequently used and helpful tools that I've collected or developed over the years.

Right now, it's pretty sparse for 2 files:
* `datecheck` written to display simple information to the screen every 3 seconds. Originally written to defeat SSH timeout sessions...
* `findchildren` kept getting issues with deleting docker images complaining about 

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
