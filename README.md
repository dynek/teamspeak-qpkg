Description
===========
TeamSpeak is flexible, powerful, scalable software which allows groups of people to speak with one another over the Internet.

This it the sources to create a QPKG installable on a QNAP device (x86-based only).

Building QPKG
=============
Following files/directories should be extracted from Linux Server x86 tgz and copied/moved inside src/x86 directory:

	doc/
	libgcc_s.so.1
	libts3db_mysql.so
	libts3db_sqlite3.so
	serverquerydocs/
	sql/
	ts3server_linux_x86

This has to be done manually upon each release - Feel free to participate if you feel like writing a script to make things better :-)

File `src/qpkg.conf` contains information about QPKG. You will most likely want to change `QPKG_VER` (*As a matter of information, ending integer is increased upon each release*).

Make sure [QDK](http://wiki.qnap.com/wiki/QPKG_Development_Guidelines) is installed on your QNAP and simply run from qpkg / src directory:

	qbuild --force-config

Build result will be located in src/build.
