#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))
CONFIGFILE=$SCRIPTPATH/$(basename $0).config
DEBUGLOGFILE=$SCRIPTPATH/$(basename $0).log
DEBUG=1
SENDDEBUG=0

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

# debug logging
function f_logging () {
  if [[ $DEBUG != 0 ]]; then
    DATE=`date '+%Y-%m-%d_%H.%M.%S'`
    echo $DATE $* >> $DEBUGLOGFILE 2>> $DEBUGLOGFILE
  fi
}

# send debug by email
# after sending, debug log will be emptied!
function f_mail () {
  if [[ $SENDDEBUG != 0 ]]; then
    cat $DEBUGLOGFILE | mail -s "[${HOSTNAME}] $(basename $0) debug log" $AUTHEMAIL
    echo > $DEBUGLOGFILE
    exit 0
  fi
}

f_logging "CONFIGFILE=$CONFIGFILE"
f_logging "AUTHKEY=$AUTHKEY"
f_logging "DNSENTRY=$DNSENTRY"
f_logging "AUTHEMAIL=$AUTHEMAIL"

DOMAIN=$(echo $DNSENTRY | awk -F. '{i=NF-1;print $i"."$NF}')
f_logging "DOMAIN=$DOMAIN"

## main

# get zone ID
f_logging "before getting ZONEID"
f_logging "ZONEID=$ZONEID"
if [[ -z $ZONEID ]]; then
  ZONEID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
      -H "Authorization: Bearer $AUTHKEY" \
      -H "Content-Type: application/json" | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name==($DOMAIN)) | .id')

  echo "ZONEID=$ZONEID" >> $CONFIGFILE
fi
f_logging "after getting ZONEID"
f_logging "ZONEID=$ZONEID"

# get DNS record ID
f_logging "before getting DNSID"
f_logging "DNSID=$DNSID"
if [[ -z $DNSID ]]; then
  DNSID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records?type=A&name=$DNSENTRY" \
       -H "Authorization: Bearer $AUTHKEY" \
       -H "Content-Type: application/json" | jq -r '.result[] | .id')
  echo "DNSID=$DNSID" >> $CONFIGFILE
fi
f_logging "after getting DNSID"
f_logging "DNSID=$DNSID"


# get current public IP
f_logging "before getting PUBLICIP"
f_logging "PUBLICIP=$PUBLICIP"
f_logging "LASTPUBLICIP=$LASTPUBLICIP"
PUBLICIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
if [[ -z $LASTPUBLICIP ]]; then
  echo "LASTPUBLICIP=$PUBLICIP" >> $CONFIGFILE
  f_logging "updating $CONFIGFILE with LASTPUBLICIP=$PUBLICIP"
fi
f_logging "after getting PUBLICIP"
f_logging "PUBLICIP=$PUBLICIP"
f_logging "LASTPUBLICIP=$LASTPUBLICIP"


# update DNS
if [[ $LASTPUBLICIP != $PUBLICIP ]]; then
   curl -s -o /dev/null -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/$DNSID" \
     -H "Authorization: Bearer $AUTHKEY" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'"$DNSENTRY"'","content":"'"$PUBLICIP"'"}'
   sed -i 's/LASTPUBLICIP.*/LASTPUBLICIP='$PUBLICIP'/' $CONFIGFILE
fi

f_mail