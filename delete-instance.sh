#!/usr/bin/env bash

export LOCAL_REPO=/fvtt/repos/${CI_PROJECT_NAME}
pm2 delete ${INSTANCE_NAME}
rm /fvtt/nginx-conf.d/${INSTANCE_NAME}.conf
rm -rf /fvtt/instances/${INSTANCE_NAME}
rm -rf $LOCAL_REPO