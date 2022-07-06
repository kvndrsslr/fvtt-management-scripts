#!/usr/bin/env bash

REMOTE_URL=https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_URL#https://}/${CI_PROJECT_PATH}.git
LOCAL_REPO=/fvtt/repos/${CI_PROJECT_NAME}
FOUNDRY_LOGS=/fvtt/instances/${INSTANCE_NAME}/Data/logs

if [[ ! -d /fvtt/repos/${CI_PROJECT_NAME} ]];
then
  /fvtt/fvtt-management-scripts/create-instance.sh
  sleep 5
fi

git -C ${LOCAL_REPO} remote set-url origin ${REMOTE_URL}
git -C ${LOCAL_REPO} pull

pm2 stop ${INSTANCE_NAME}

cp /fvtt/instances/.users.db /fvtt/instances/${INSTANCE_NAME}/Data/worlds/${INSTANCE_NAME}/data/users.db

yq '.dependencies[] | select( .method == "git-public" ) | select( .type == "system" ) | .url' ${LOCAL_REPO}/.fvtt-dependencies.yml | \
xargs -I {} -d '\n' \
sh -c 'x="{}"; x="${x##*/}"; x="${x%.git}"; git -C /fvtt/dependencies/$x pull' sh

yq '.dependencies[] | select( .method == "git-public" ) | select( .type == "module" ) | .url' ${LOCAL_REPO}/.fvtt-dependencies.yml | \
xargs -I {} -d '\n' \
sh -c 'x="{}"; x="${x##*/}"; x="${x%.git}"; git -C /fvtt/dependencies/$x pull' sh

yq '.dependencies[] | select( .method == "git-sigil" ) | select( .type == "system" ) | .path' ${LOCAL_REPO}/.fvtt-dependencies.yml | \
xargs -I {} -d '\n' \
sh -c 'x="{}"; x="${x##*/}"; x="${x%.git}"; git -C /fvtt/dependencies/$x remote set-url origin "https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_URL#https://}{}" ; git -C /fvtt/dependencies/$x pull ; ' sh

yq '.dependencies[] | select( .method == "git-sigil" ) | select( .type == "module" ) | .path' ${LOCAL_REPO}/.fvtt-dependencies.yml | \
xargs -I {} -d '\n' \
sh -c 'x="{}"; x="${x##*/}"; x="${x%.git}"; git -C /fvtt/dependencies/$x remote set-url origin "https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_URL#https://}{}" ; git -C /fvtt/dependencies/$x pull' sh

#rm -rf ${LOCAL_REPO}/html
#cp -r ${CI_PROJECT_DIR}/html ${LOCAL_REPO}/.
rm -f ${FOUNDRY_LOGS}/${CI_PROJECT_NAME}-namedIndex-*.json 

pm2 start ${INSTANCE_NAME}