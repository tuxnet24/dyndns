#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))
CONFIGFILE=$SCRIPTPATH/${0}.config

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
echo "LASTPUBLICIP=$PUBLICIP" >> $CONFIGFILE

# update DNS
if [[ $LASTPUBLICIP != $PUBLICIP ]]; then
   curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/$DNSID" \
     -H "X-Auth-Email: $AUTHEMAIL" \
     -H "X-Auth-Key: $AUTHKEY" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'"$DNSENTRY"'","content":"'"$PUBLICIP"'"}'
fi