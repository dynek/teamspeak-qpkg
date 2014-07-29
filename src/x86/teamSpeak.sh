#!/bin/sh

QPKG_NAME="TeamSpeak"
QPKG_DIR=""
CONF=/etc/config/qpkg.conf
PIDFILE="$QPKG_DIR/${QPKG_NAME}.pid"
PUBLIC_SHARE=`/sbin/getcfg Public path -f /etc/config/smb.conf`
LICENSEKEY_FILE="${PUBLIC_SHARE}/licensekey.dat"
SERVERKEY_FILE="${PUBLIC_SHARE}/serverkey.dat"

find_base()
{
        # Determine BASE installation location according to smb.conf
        publicdir=`/sbin/getcfg Public path -f /etc/config/smb.conf`
        if [ ! -z $publicdir ] && [ -d $publicdir ];then
                publicdirp1=`/bin/echo $publicdir | /bin/cut -d "/" -f 2`
                publicdirp2=`/bin/echo $publicdir | /bin/cut -d "/" -f 3`
                publicdirp3=`/bin/echo $publicdir | /bin/cut -d "/" -f 4`
                if [ ! -z $publicdirp1 ] && [ ! -z $publicdirp2 ] && [ ! -z $publicdirp3 ]; then
                        [ -d "/${publicdirp1}/${publicdirp2}/Public" ] && QPKG_BASE="/${publicdirp1}/${publicdirp2}"
                fi
        fi

        # Determine BASE installation location by checking where the Public folder is.
        if [ -z $QPKG_BASE ]; then
                for datadirtest in /share/HDA_DATA /share/HDB_DATA /share/HDC_DATA /share/HDD_DATA /share/HDE_DATA /share/HDF_DATA /share/HDG_DATA /share/HDH_DATA /share/MD0_DATA /share/MD1_DATA /share/MD2_DATA /share/MD3_DATA; do
                        [ -d $datadirtest/Public ] && QPKG_BASE="$datadirtest"
                done
        fi
        if [ -z $QPKG_BASE ] ; then
                echo "The Public share not found."
                exit 1
        fi
        QPKG_DIR="${QPKG_BASE}/.qpkg/${QPKG_NAME}"
}

find_base

case "$1" in
	start)
		ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
		if [ "$ENABLED" != "TRUE" ]; then
			echo "$QPKG_NAME is disabled."
			if [ "$2" != "force" ]; then
				exit 1
			else
				echo "Forcing startup..."
			fi
		fi

		PID=`/bin/ps -eo 'pid,cmd'| grep 'ts3server_linux_' | grep -v grep | awk '{sub("^ ", "", $0); print $0}' | cut -d " " -f 1`
		if [[ -n "$PID" ]]; then
			echo "$QPKG_NAME is already running with pid $PID!"
			exit 1
		fi


		# Check if licence can be found in public share
		if [[ -f $LICENSEKEY_FILE ]] ; then
			echo "Licence key found and copied to QPKG directory."
			/bin/mv $LICENSEKEY_FILE "${QPKG_DIR}/"
		fi
		if [[ -f $SERVERKEY_FILE ]] ; then
			echo "Server key found and copied to QPKG directory."
			/bin/mv $SERVERKEY_FILE "${QPKG_DIR}/"
		fi

                echo "Starting ${QPKG_NAME}... "
		export LD_LIBRARY_PATH="${QPKG_DIR}:${LD_LIBRARY_PATH}"
		cd $QPKG_DIR
		./ts3server_linux_x86 > /dev/null &
		if [[ $! -gt 0 ]]; then
			echo $! > $PIDFILE
			exit 0
		else
			exit 1
		fi
                ;;

	stop)
                echo "Stopping ${QPKG_NAME}... "
		if [[ -f $PIDFILE ]] ; then
			kill `/bin/cat $PIDFILE`
			/bin/sleep 10
		fi
		PID=`/bin/ps -eo 'pid,cmd'| grep 'ts3server_linux_' | grep -v grep | awk '{sub("^ ", "", $0); print $0}' | cut -d " " -f 1`
		if [[ -n "$PID" ]]; then
			echo "Still running, killing PID=$PID ... "
			kill -9 $PID
		fi
		rm -f $PIDFILE
		exit 0
                ;;

        restart)
                $0 stop
		/bin/sleep 5
                $0 start
		exit 0
                ;;
	status)
		PID=`/bin/ps -eo 'pid,cmd'| grep 'ts3server_linux_' | grep -v grep | awk '{sub("^ ", "", $0); print $0}' | cut -d " " -f 1`
		if [[ -n "$PID" ]]; then
			echo "$QPKG_NAME (pid $PID) is running."
		else
			echo "$QPKG_NAME is stopped."
		fi
		exit 0
		;;
	*)
                echo "Usage: $0 {start|stop|restart|status}"
                exit 1
esac
