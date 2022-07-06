#!/usr/bin/env bash

REMOTE_URL=https://kxfin:${SIGIL_CI_PUSH_TOKEN}@${CI_SERVER_URL#https://}/${CI_PROJECT_PATH}.git
LOCAL_REPO=/fvtt/repos/${CI_PROJECT_NAME}
FOUNDRY_LOGS=/fvtt/instances/${INSTANCE_NAME}/Data/logs

pm2 stop ${INSTANCE_NAME}
git -C ${LOCAL_REPO} remote set-url origin ${REMOTE_URL}
git -C ${LOCAL_REPO} pull
git -C ${LOCAL_REPO} config user.email "gitlab@sigil.info"
git -C ${LOCAL_REPO} config user.name "SIGIL CI"
cp ${FOUNDRY_LOGS}/${CI_PROJECT_NAME}-namedIndex-*.json ${LOCAL_REPO}/source/${CI_PROJECT_NAME}-namedIndex.json
git -C ${LOCAL_REPO} add ${LOCAL_REPO}/source/${CI_PROJECT_NAME}-namedIndex.json
git -C ${LOCAL_REPO} commit -m "SIGIL CI: updating named index"
git -C ${LOCAL_REPO} push -o ci.skip
pm2 start ${INSTANCE_NAME}