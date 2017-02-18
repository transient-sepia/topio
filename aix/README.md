AIX has nmon that can sort on process I/O.

Manual check: start nmon, press t then 5 to sort on I/O.

You can set an alias too, e.g. like this:

    alias topio='NMON=u5 nmon'

That's pretty much it.
