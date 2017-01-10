#!/bin/bash
## cdda-copy by Marc Wernecke 2016-12-23

### Setup Begin ###
DEVICE="IOService:/AppleACPIPlatformExpert/PCI0@0/AppleACPIPCI/SAT0@1F,2/AppleIntelPchSeriesAHCI/SPT5@5/IOAHCIDevice@0/IOAHCISerialATAPI/IOSCSIPeripheralDeviceNub/IOSCSIPeripheralDeviceType05/IODVDServices"
DISK=/dev/disk2

DRIVER=generic-mmc
WORKDIR=~/CdrDAO
DELAY=10
### Setup End ###


## Version
echo "cdda-copy 0.1"


## Helper
waitForDevice ()
{
  _DELAY=$1
  echo -n "Waiting for Device "

  while [ $_DELAY -gt 0 ]
  do
    echo -n "$_DELAY "
    let "_DELAY-=1"
    sleep 1
  done
  echo ""
  echo ""
}

## Check executable
EXECUTABLE="$(which cdrdao)"
if [ ! -x "$EXECUTABLE" ]; then
  read -p "cdrdao not found, install now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ## Install homebrew:
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null
    ## Install cdrdao:
    brew install cdrdao
    echo ""
    echo "Install done"
    echo "Starting Setup ..."
    echo ""
    read -p "Remove any CD, close the tray and hit a key " -n 1 -r
    echo ""
    waitForDevice 5
    cdrdao scanbus    
    echo ""
    read -p "Insert an Audio-CD, close the tray and hit a key " -n 1 -r
    echo ""
    waitForDevice $DELAY
    diskutil list
    echo
    echo "Please edit the script's setup to fit your needs. "
    echo "See the terminal output above to adjust DEVICE and DISK "
    echo "You have to do this only once, then start cdda-copy again. " 
    echo ""
    echo "Your favorite editor should now pop up and open the file and "
    echo "cdda-copy will terminate ... "
    echo ""
    open -e "$0"
  fi
  exit
fi

## Option
case $# in
  0) 
    echo "Type the name for your project, followed by [ENTER]:"
    read NAME
    [ "$NAME"x != x ] || exit;;
  1) 
    NAME="$1";;
  *) 
    echo 'Usage: cdda-copy "My super fancy Audio-CD"'; exit 1;;
esac

## Working directory
if [ -d "$WORKDIR/$NAME" ]; then
  read -p "\"$WORKDIR/$NAME\" already exits, delete now? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
	rm -Rf "$WORKDIR/$NAME"
	mkdir -p "$WORKDIR/$NAME"
  fi
else
  mkdir -p "$WORKDIR/$NAME"
fi

cd "$WORKDIR/$NAME"

## Read-CD
if [ -f "$NAME.bin" ] && [ -f "$NAME.toc" ]; then
  echo "Found $NAME.bin and $NAME.toc"
  echo "Skip reading"
else
  read -p "Insert an Audio-CD, close the tray and hit a key " -n 1 -r
  echo ""
  waitForDevice $DELAY
  diskutil umount $DISK
  cdrdao read-cd --device "$DEVICE" --driver "$DRIVER" --read-raw --with-cddb --datafile "$NAME.bin" "$NAME.toc"
fi

## Write
while true; do
  drutil eject
  read -p "Insert an empty CD and hit [B] " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Bb]$ ]]; then
    waitForDevice $DELAY
    cdrdao write --device "$DEVICE" --driver "$DRIVER" "$NAME.toc"
  else
    break
  fi
done

echo "cdda-copy - Done"
