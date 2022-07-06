#!/usr/bin/env bash

REMOTE_URL=https://kxfin:${SIGIL_CI_PUSH_TOKEN}@${CI_SERVER_URL#https://}/${CI_PROJECT_PATH}.git
LOCAL_REPO=/fvtt/repos/${CI_PROJECT_NAME}

pm2 stop ${INSTANCE_NAME}
git -C ${LOCAL_REPO} remote set-url origin ${REMOTE_URL}
git -C ${LOCAL_REPO} pull
git -C ${LOCAL_REPO} config user.email "gitlab@sigil.info"
git -C ${LOCAL_REPO} config user.name "SIGIL CI"
rm -rf ${LOCAL_REPO}/worldbackup
mkdir -p ${LOCAL_REPO}/worldbackup
cp -rf /fvtt/instances/${INSTANCE_NAME}/Data/worlds/${INSTANCE_NAME} ${LOCAL_REPO}/worldbackup
git -C ${LOCAL_REPO} add .
git -C ${LOCAL_REPO} commit -m "SIGIL CI: backing up world"
git -C ${LOCAL_REPO} push -o ci.skip
pm2 start ${INSTANCE_NAME}