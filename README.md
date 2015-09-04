rFsync client

====================================================================================
A free rfactor synchronization tool for
* The leagues:
- easily distributes tracks and mods content of your events
- no more archives to update content: do it through rfsync !
- no more mismatches: rfsync checks content integrity at each synch launched by drivers
- if a content fix must be distributed few minutes before an event, be confident to do it through synch!
- rfsync tool is updated automatically: drivers have not to install it at each update
- add/delete seasons (season=tracks+mod) as you wish
- protect content with a passworded access to rfsync client
- you are independent with rFsync: no dependency with other services, no authorization to get and rfsync client updates are not mandatory: you decide!
- you can contribute to rFsync: it is under GPLv3 licence

* The drivers:
- easily installs tracks and mods content
- gets the last content updates
- checks your content integrity at each synch
- synch only the subscribed season(s) (season=tracks+mod)

As a free tool: install, configure and use it freely !

How it works:
2 parts:
* rFsync server side, leagues stuff:
- host it on linux or windows server, mostly on your windows server asides rfactor dedicated servers
- install, configure and start a rsync server
- build the repository structure from the template
- upload your content in repository structure
- build synch files of your content
- configure the rfsync client to distribute to drivers
- give a link to rfsync client to drivers !

* rFsync client side, drivers stuff:
- get rfsync tool configured for the league
- install rfsync tool in your rfactor directory
- launch rfsync tool !

====================================================================================

Used by Old Drivers Spirit, Simuracing leagues and for the LMC event.

====================================================================================
Developped with rsync/dialog/cygwin/bash.

rsync: https://rsync.samba.org/

dialog: http://bash.cyberciti.biz/guide/Bash_display_dialog_boxes

cygwin: https://www.cygwin.com/

bash: http://en.wikipedia.org/wiki/Bash_%28Unix_shell%29
