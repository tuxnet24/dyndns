#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))
CONFIGFILE=$SCRIPTPATH/$(basename $0).config
DEBUGLOGFILE=$SCRIPTPATH/$(basename $0).log
EMAIL=dasganze@gmail.com
DEBUG=1
SENDDEBUG=1


# debug logging
function f_logging () {
  if [[ DEBUG != "0" ]]; then
    DATE=`date '+%Y-%m-%d_%H.%M.%S'`
    echo $DATE $* >> $DEBUGLOGFILE 2>> $DEBUGLOGFILE
  fi
}

# send debug by email
# after sending, debug log will be emptied!
function f_mail () {
  if [[ SENDDEBUG != "0" ]]; then
    cat $DEBUGLOGFILE | mail -s "[${HOSTNAME}] $(basename $0) debug log" $EMAIL
    echo > $DEBUGLOGFILE
    exit 0
  fi
}

# variables needed in $CONFIGFILE
# AUTHKEY=xxxxxxxxxxxxxxxxxxxxxxx
# DNSENTRY=fq.dn.de
# AUTHEMAIL=xx@yy.ZZ
# make this config file writeable for the user who is running this script
if [[ -f $CONFIGFILE ]]; then
  . $CONFIGFILE
else
  echo "ERROR: $CONFIGFILE not found!"
  exit 1
fi

f_logging "CONFIGFILE=$CONFIGFILE"
f_logging "$(env)"

DOMAIN=$(echo $DNSENTRY | awk -F. '{i=NF-1;print $i"."$NF}')

## main

# get zone ID
if [[ -z $ZONEID ]]; then
  ZONEID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
      -H "X-Auth-Email: $AUTHEMAIL" \
      -H "X-Auth-Key: $AUTHKEY" \
      -H "Content-Type: application/json" | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name==($DOMAIN)) | .id')

  echo "ZONEID=$ZONEID" >> $CONFIGFILE
fi

# get DNS record ID
if [[ -z $DNSID ]]; then
  DNSID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records?type=A&name=$DNSENTRY" \
       -H "X-Auth-Email: $AUTHEMAIL" \
       -H "X-Auth-Key: $AUTHKEY" \
       -H "Content-Type: application/json" | jq -r '.result[] | .id')

  echo "DNSID=$DNSID" >> $CONFIGFILE
fi

# get current public IP
PUBLICIP=$(curl -s ifconfig.co)
if [[ -z $LASTPUBLICIP ]]; then
  echo "LASTPUBLICIP=$PUBLICIP" >> $CONFIGFILE
fi


# update DNS
if [[ $LASTPUBLICIP != $PUBLICIP ]]; then
   curl -s -o /dev/null -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/$DNSID" \
     -H "X-Auth-Email: $AUTHEMAIL" \
     -H "X-Auth-Key: $AUTHKEY" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'"$DNSENTRY"'","content":"'"$PUBLICIP"'"}'
   sed -i 's/LASTPUBLICIP.*/LASTPUBLICIP='$PUBLICIP'/' $CONFIGFILE
fi

f_mail