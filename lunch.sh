#!/bin/bash

source ~/.picam360rc

CURRENT=$(cd $(dirname $0) && pwd)
cd $CURRENT

usage_exit() {
        echo "Usage: $0 [-w width] [-h height] item ..." 1>&2
        exit 1
}

CAM_NUM=1
CAM_WIDTH=2048
CAM_HEIGHT=2048
BITRATE=8000000
RENDER_WIDTH=1440
RENDER_HEIGHT=720
PREVIEW=
REMOTE=false
STEREO=
MODE=
DIRECT=
FPS=30
CODEC=H264
STREAM=
AUTO_CALIBRATION=
VIEW_COODINATE=manual
DEBUG=false
KBPS=
FRAME0_PARAM=

while getopts ac:n:w:h:psf:rDv:g0: OPT
do
    case $OPT in
        a)  AUTO_CALIBRATION="-a"
            ;;
        c)  CODEC=$OPTARG
            ;;
        n)  CAM_NUM=$OPTARG
            ;;
        w)  CAM_WIDTH=$OPTARG
            ;;
        h)  CAM_HEIGHT=$OPTARG
            ;;
        p)  PREVIEW="-p"
            ;;
        s)  STEREO="-s"
            ;;
        f)  FPS=$OPTARG
            ;;
        r)  REMOTE=true
            ;;
        D)  DIRECT="-D"
            ;;
        v)  VIEW_COODINATE=$OPTARG
            ;;
        g)  DEBUG=true
            ;;
        0)  FRAME0_PARAM=$OPTARG
            ;;
        \?) usage_exit
            ;;
    esac
done

if [ -e status ]; then
	rm status
fi
mkfifo status
chmod 0666 status

if [ -e cam0 ]; then
	rm cam0
fi
mkfifo cam0
chmod 0666 cam0

if [ -e cam1 ]; then
	rm cam1
fi
mkfifo cam1
chmod 0666 cam1

if [ -e rtp_rx ]; then
	rm rtp_rx
fi
mkfifo rtp_rx
chmod 0666 rtp_rx

if [ -e rtp_tx ]; then
	rm rtp_tx
fi
mkfifo rtp_tx
chmod 0666 rtp_tx

if [ -e rtcp_rx ]; then
	rm rtcp_rx
fi
mkfifo rtcp_rx
chmod 0666 rtcp_rx

if [ -e rtcp_tx ]; then
	rm rtcp_tx
fi
mkfifo rtcp_tx
chmod 0666 rtcp_tx

if [ $REMOTE = true ]; then

	if [ "$DRIVER_IP" = "" ]; then
		DRIVER_IP="192.168.4.1"
	fi
	
	if [ "$SERVER_IP" = "" ]; then
		SERVER_IP="192.168.4.2"
	fi

#use tcp
#	sudo killall nc
#   nc 192.168.4.1 9006 < rtp_tx > rtp_rx &

	SOCAT=socat
	if type socat2 >/dev/null 2>&1; then
		SOCAT=socat2
	fi

	sudo killall $SOCAT
#	$SOCAT -u udp-recv:9002 - > rtp_rx &
	$SOCAT PIPE:rtcp_tx UDP-DATAGRAM:$DRIVER_IP:9003 &
#	$SOCAT PIPE:rtp_tx UDP-DATAGRAM:$SERVER_IP:9004 &
	$SOCAT -u udp-recv:9005 - > rtcp_rx &

elif [ $DIRECT = ]; then
	sudo killall raspivid
	if [ $CODEC = "MJPEG" ]; then
#		raspivid -cd MJPEG -n -t 0 -w $CAM_WIDTH -h $CAM_HEIGHT -ex sports -b $BITRATE -fps $FPS -o - > cam0 &
		raspivid -cd MJPEG -n -t 0 -w $CAM_WIDTH -h $CAM_HEIGHT -b $BITRATE -fps $FPS -o - > cam0 &
	else
		raspivid -n -t 0 -w $CAM_WIDTH -h $CAM_HEIGHT -ex sports -ih -b $BITRATE -fps $FPS -o - > cam0 &
	fi
fi

#picam360-capture

sudo killall picam360-capture.bin
if [ $DEBUG = "true" ]; then

echo b main > gdbcmd
echo r $AUTO_CALIBRATION -c $CODEC -n $CAM_NUM -w $CAM_WIDTH -h $CAM_HEIGHT $DIRECT $STEREO $PREVIEW -v $VIEW_COODINATE -F \"$FRAME0_PARAM\" >> gdbcmd
gdb ./picam360-capture.bin -x gdbcmd

else

./picam360-capture.bin $AUTO_CALIBRATION -c $CODEC -n $CAM_NUM -w $CAM_WIDTH -h $CAM_HEIGHT $DIRECT $STEREO $PREVIEW -v $VIEW_COODINATE -F "$FRAME0_PARAM"

fi