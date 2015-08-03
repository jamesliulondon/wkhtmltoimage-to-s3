#!/bin/bash 

#author JamesLiu
RECIPIENTS="syseng@performgroup.com,hemna.juneja@performgroup.com,jamescliu@hotmail.com"
TMPFILE=/var/tmp/nagios_dashview_random.txt 
PID=$$ 
S3_BUCKET="sportal-jamesliu-test"
S3_HOST="https://s3-us-west-1.amazonaws.com"
POLL_INTERVAL=300
TIDE_MARK="04:00"
NEXT_NOTIFICATION=""

function exit_code() 
# Exit with message and clean up 
{ 
  if [ ! -z "$2" ]; then 
    echo $2 
  fi 
  if [ -f /var/tmp/dash_${FILE_UID}.png ]; then 
    /bin/rm /var/tmp/dash_${FILE_UID}.png 
  fi 
#  if [ -f /var/tmp/dash_${FILE_UID}.png ]; then 
#    /bin/rm /var/tmp/dash_${FILE_UID}.png 
#  fi 
  if [ -f /var/tmp/index_${FILE_UID}.html ]; then 
    /bin/rm /var/tmp/index_${FILE_UID}.html 
  fi 
  exit $1 
} 

function upload_new_html()
{
get_next_notifcation
get_next_file_uid

s3cmd del s3://$S3_BUCKET/index.*.html > /dev/null 
s3cmd del s3://$S3_BUCKET/dash*.png > /dev/null 
rm /var/tmp/index.*.html
rm /var/tmp/dash_*.png

# Create HTML file 
cat <<EOF>/var/tmp/index.${FILE_UID}.html
<html> 
<head> 
<title>CheckMK Dashview</title> 
<style>body { background-color: black; }</style> 
<meta http-equiv="refresh" content="150"/> 
<meta name="apple-mobile-web-app-capable" content="yes"> 
</head> 
<body> 
<img src="dash_${FILE_UID}.png" style="position: absolute; width:100%; top: 0"/> 
</body> 
</html> 
EOF
[ $? -ne 0 ] && exit_code 4 "Failed to create new random string file" 
s3cmd put /var/tmp/index.${FILE_UID}.html s3://${S3_BUCKET}/index.${FILE_UID}.html


# Mail out the new URL 
/bin/mailx -s "Daily CheckMK Dashboard" ${RECIPIENTS} <<END_OF_MAIL 

$S3_HOST/$S3_BUCKET/index.${FILE_UID}.html 

Link will change at $TIDE_MARK

Tell no one 
END_OF_MAIL

}

function get_next_notifcation()
{
    echo "getting next notification time"
    TOMORROW=`date --date '+1 day' '+%m/%d/%Y'`
    echo $TOMORROW
    NEXT_NOTIFICATION=$(date -d "${TOMORROW} ${TIDE_MARK}" +%s)
    echo $NEXT_NOTIFICATION
}

function get_next_file_uid() {
    FILE_UID=`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;`
    [ -z $FILE_UID ] && exit_code 5 "Failed to generate new random string" 
    echo "New file uid: $FILE_UID"
}

function create_dashboard_image()
{
    wkhtmltoimage --quality 50  --zoom 0.75 'http://172.16.2.30/check_mk/view.py?view_name=svcproblems&_username=techsupport_mon&_secret=NPWTRFDJFQIHCMJAAVLG' /var/tmp/dash_${FILE_UID}.png
}

function upload_image()
{
    create_dashboard_image
    s3cmd put /var/tmp/dash_${FILE_UID}.png s3://${S3_BUCKET}/dash_${FILE_UID}.png
}

while true;
do
    echo "beginning cycle"
    if [ ! ${FILE_UID} ]; then upload_new_html; fi

    NOW=`date '+%s'`

    if [ ${NOW} -gt ${NEXT_NOTIFICATION} ]; then
        upload_new_html
    fi

    upload_image
    sleep $POLL_INTERVAL
done
