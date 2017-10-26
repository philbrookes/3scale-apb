#!/bin/sh

THREESCALE_ACCESS_TOKEN=$1
THREESCALE_DOMAIN=$2
THREESCALE_SERVICE_ID=$3
APICAST_URL=${4%/}
SERVICE_URL=${5%/}
SERVICE_NAME=$6
APP_KEY=$7

set -x

####################################################
# Configure the Service for App ID/Key Auth & Self Managed APIcast
####################################################
# Service Update - PUT /admin/api/services/{id}.json
# name => 'Sync Service (Managed by MCP)'
# deployment_option => 'self_managed' (APIcast)
# backend_version => '2' (for App Id / App Key)
HTTP_CODE=$(curl -X PUT -s -o /dev/null -w "%{http_code}" -d "access_token=$THREESCALE_ACCESS_TOKEN&name=$SERVICE_NAME&deployment_option=self_managed&backend_version=2" "$THREESCALE_DOMAIN/admin/api/services/$THREESCALE_SERVICE_ID.json")

if [ "$HTTP_CODE" -ne "200" ]
then
  echo "Bad http code ($HTTP_CODE)"
  exit 1
fi

####################################################
# Configure the Service Proxy settings
####################################################
# * Proxy Update - PATCH /admin/api/services/{service_id}/proxy.xml
# ** endpoint => APIcast Route e.g. http://apicast-myproject.192.168.37.1.nip.io:80
# ** api_backend => Sync Service Route e.g. https://fh-sync-server-myproject.192.168.37.1.nip.io:443
# ** credentials_location => 'headers'
# ** auth_app_key => 'app_key'
# ** auth_app_id => 'app_id'
# ** error_status_auth_failed => '403'
# ** error_status_auth_missing => '403'
# ** error_status_no_match => '404'
# ** (in future) secret_token => 'some_secret_string_to_inject_into_sync_service'
HTTP_CODE=$(curl -X PATCH -s -o /dev/null -w "%{http_code}" -d "access_token=$THREESCALE_ACCESS_TOKEN&endpoint=$APICAST_URL&api_backend=$SERVICE_URL&credentials_location=headers&auth_app_key=app_key&auth_app_id=app_id&error_status_auth_failed=403&error_status_auth_missing=403&error_status_no_match=404" "$THREESCALE_DOMAIN/admin/api/services/$THREESCALE_SERVICE_ID/proxy.json")

if [ "$HTTP_CODE" -ne "200" ]
then
  echo "Bad http code ($HTTP_CODE)"
  exit 1
fi

####################################################
# Configure GET & POST Mappings for the Service
####################################################
# * Metric List - GET /admin/api/services/{service_id}/metrics.xml
METRIC_LIST=$(curl -X GET -s -d "access_token=$THREESCALE_ACCESS_TOKEN" "$THREESCALE_DOMAIN/admin/api/services/$THREESCALE_SERVICE_ID/metrics.json")

exit_status=$?
if [ ! $exit_status -eq 0 ]; then
  echo "Bad exit status ($exit_status)"
  exit 1
fi

METRIC_ID=$(echo ${METRIC_LIST} | jq .metrics[0].metric.id)

# * Mapping Rule Create - POST /admin/api/services/{service_id}/proxy/mapping_rules.xml
# ** http_method => 'GET' & 'POST'
# ** pattern => '/'
# ** delta => '1'
# ** metric_id => (id from Metric Read response)
HTTP_CODE=$(curl -X POST -s -o /dev/null -w "%{http_code}" -d "access_token=$THREESCALE_ACCESS_TOKEN&http_method=GET&pattern=%2F&delta=1&metric_id=$METRIC_ID" "$THREESCALE_DOMAIN/admin/api/services/$THREESCALE_SERVICE_ID/proxy/mapping_rules.json")

if [ "$HTTP_CODE" -ne "201" ]
then
  echo "Bad http code ($HTTP_CODE)"
  exit 1
fi

HTTP_CODE=$(curl -X POST -s -o /dev/null -w "%{http_code}" -d "access_token=$THREESCALE_ACCESS_TOKEN&http_method=POST&pattern=%2F&delta=1&metric_id=$METRIC_ID" "$THREESCALE_DOMAIN/admin/api/services/$THREESCALE_SERVICE_ID/proxy/mapping_rules.json")

if [ "$HTTP_CODE" -ne "201" ]
then
  echo "Bad http code ($HTTP_CODE)"
  exit 1
fi

####################################################
# Promote the Proxy Config to production
####################################################
# * Proxy Config Show Latest - GET /admin/api/services/{service_id}/proxy/configs/{environment}/latest.json
# ** environment => 'sandbox'
PROXY_CONFIG_LATEST=$(curl -X GET -s -d "access_token=$THREESCALE_ACCESS_TOKEN" "$THREESCALE_DOMAIN/admin/api/services/$THREESCALE_SERVICE_ID/proxy/configs/sandbox/latest.json")

exit_status=$?
if [ ! $exit_status -eq 0 ]; then
  echo "Bad exit status ($exit_status)"
  exit 1
fi

PROXY_CONFIG_VERSION=$(echo ${PROXY_CONFIG_LATEST} | jq .proxy_config.version)

# * Proxy Config Promote - POST /admin/api/services/{service_id}/proxy/configs/{environment}/{version}/promote.json
# ** environment => 'sandbox' (From/Gateway environment)
# ** version => (taken from the 'version' in 'Proxy Config Show Latest' response)
# ** to => 'production' (To environment)
HTTP_CODE=$(curl -X POST -s -o /dev/null -w "%{http_code}" -d "access_token=$THREESCALE_ACCESS_TOKEN&to=production" "$THREESCALE_DOMAIN/admin/api/services/$THREESCALE_SERVICE_ID/proxy/configs/sandbox/$PROXY_CONFIG_VERSION/promote.json")

if [ "$HTTP_CODE" -ne "201" ]
then
  echo "Bad http code ($HTTP_CODE)"
  exit 1
fi

####################################################
# Create an App Key
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

APPLICATION_ID=$(echo ${APPLICATION_LIST} | jq .applications[0].application.id)
ACCOUNT_ID=$(echo ${APPLICATION_LIST} | jq .applications[0].application.account_id)

# * Application Key Create (to set the app key) - POST /admin/api/accounts/{account_id}/applications/{application_id}/keys.xml
# ** account_id => (taken from the 'user_account_id' in Application List response)
# ** application_id => (taken from the 'id' in Application List response)
# ** key => (key value)
HTTP_CODE=$(curl -X POST -s -o /dev/null -w "%{http_code}" -d "access_token=$THREESCALE_ACCESS_TOKEN&key=$APP_KEY" "$THREESCALE_DOMAIN/admin/api/accounts/$ACCOUNT_ID/applications/$APPLICATION_ID/keys.json")

if [ "$HTTP_CODE" -ne "201" ]
then
  echo "Bad http code ($HTTP_CODE)"
  exit 1
fi
