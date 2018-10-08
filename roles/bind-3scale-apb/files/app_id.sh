#!/bin/sh

THREESCALE_ACCESS_TOKEN=$1
THREESCALE_DOMAIN=$2
THREESCALE_SERVICE_ID=$3

####################################################
# Get the app id
####################################################
# * Application List (to get the app id) - GET /admin/api/applications.xml
# ** service_id => (service id)
# ** page => 1
# ** per_page => 1 (find the first)
APPLICATION_LIST=$(curl -X GET -s -d "access_token=$THREESCALE_ACCESS_TOKEN&service_id=$THREESCALE_SERVICE_ID&page=1&per_page=1" "$THREESCALE_DOMAIN/admin/api/applications.json")

exit_status=$?
if [ ! $exit_status -eq 0 ]; then
  echo "Bad exit status ($exit_status)"
  exit 1
fi

APPLICATION_ID=$(echo ${APPLICATION_LIST} | jq .applications[0].application.application_id)
echo $APPLICATION_ID