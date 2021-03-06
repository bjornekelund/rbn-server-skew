#!/bin/bash
# Calculate and report skew estimates based on previous day's RBN data
# Also updates the file "reference" based on the same data

# Move to correct folder to allow cron execution on RPi
[ -d "/home/sm7iun/skewsrv" ] && cd /home/sm7iun/skewsrv

FOLDER="rbndata"
DATE=`date -u --date="1 days ago" +%Y%m%d`
#DATE="20200715"
OLDDATE=`date -u --date="10 days ago" +%Y%m%d`
DELFILE=$FOLDER/$OLDDATE.ref
REFFILE="reference"
CSVFILE=$FOLDER/rbndata.csv
ZIPFILE=$FOLDER/rbndata.zip
TOKEN=$FOLDER/dataupdated

[ -d $FOLDER ] || mkdir $FOLDER

echo "Job started "`date -u "+%F %T" `
START=$SECONDS

# Do the work

# Uncomment line to always download
#echo "Never" > $TOKEN

# Check if we already did the work for
# today, if so, exit
[ -f $TOKEN ] || echo "Never" > $TOKEN

if [ "$DATE" != "`cat $TOKEN`" ]; then
    echo "Downloading RBN data for "`date -u --date="1 days ago" +%Y-%m-%d`
    wget --quiet --no-hsts http://www.reversebeacon.net/raw_data/dl.php?f=$DATE -O $ZIPFILE

    FILESIZE=$(stat -c%s $ZIPFILE)
    if [[ $FILESIZE != "0" ]]; then
        gunzip < $ZIPFILE > $CSVFILE
        echo "Downloaded yesterday's "$((`wc -l < $CSVFILE` - 2))" spots into $CSVFILE"
        echo $DATE > $TOKEN
    else
        echo "Could not download yesterday's RBN data!"
        echo "Job failed "`date -u "+%F %T" `
        exit
    fi
fi

# Do the actual work

printf "Doing a two-pass analysis of the RBN data...\n"

./skewday -f $CSVFILE

# Save the five most recent reference files
cp $REFFILE $FOLDER/$DATE.ref
rm -f $DELFILE

echo "Job ended "`date -u "+%F %T" `
echo "----"

exit
