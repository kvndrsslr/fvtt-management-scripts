#!/usr/bin/env bash

REMOTE_URL=https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_URL#https://}/${CI_PROJECT_PATH}.git
LOCAL_REPO=/fvtt/repos/${CI_PROJECT_NAME}

if [[ ! -d /fvtt/repos/${CI_PROJECT_NAME} ]];
then
  git clone ${REMOTE_URL} ${LOCAL_REPO}
else
  git -C ${LOCAL_REPO} remote set-url origin ${REMOTE_URL}
  git -C ${LOCAL_REPO} pull
fi

export INSTANCE_PORT=$(comm -23 <(seq 30000 30999 | sort) <(/usr/sbin/ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
export FVTT_BIN="/fvtt/dist/${FVTT_VERSION}/resources/app/main.mjs"
export INSTANCE_DIR=/fvtt/instances/${INSTANCE_NAME}/

mkdir -p ${INSTANCE_DIR}Config

# add reverse proxy config to nginx
sed -e 's/{{NAME}}/'"${INSTANCE_NAME}"'/g' -e 's/{{PORT}}/'"${INSTANCE_PORT}"'/g' /fvtt/nginx-conf.d/.template > /fvtt/nginx-conf.d/${INSTANCE_NAME}.conf

# write instance configuration
sed -e 's/{{NAME}}/'"${INSTANCE_NAME}"'/g' -e 's/{{PORT}}/'"${INSTANCE_PORT}"'/g' /fvtt/instances/.template > ${INSTANCE_DIR}Config/options.json

cp /fvtt/instances/.users.db ${INSTANCE_DIR}/Data/worlds/${INSTANCE_NAME}/data/users.db

# sign license
node /fvtt/fvtt-management-scripts/sign.mjs

# remove password
rm -f ${INSTANCE_DIR}/Config/admin.txt

sleep 5

if ! pm2 show ${INSTANCE_NAME} &>/dev/null
then
  pm2 start ${FVTT_BIN} --name ${INSTANCE_NAME} -- --dataPath=${INSTANCE_DIR}
  pm2 save
else 
  pm2 restart ${INSTANCE_NAME}
fi

sleep 5

yq '.dependencies[] | select( .method == "fvtt" ) | select( .type == "system" ) | .manifest' ${LOCAL_REPO}/.fvtt-dependencies.yml | xargs -I {} -d '\n' \
curl -sL "https://${INSTANCE_NAME}.fvtt.sigil.info/setup" \
-X 'POST' \
-H 'Content-Type: application/json' \
-H 'Pragma: no-cache' \
-H 'Accept: */*' \
--data-binary '{"action":"installPackage","type":"system","manifest":"'"{}"'"}'

yq '.dependencies[] | select( .method == "fvtt" ) | select( .type == "module" ) | .manifest' ${LOCAL_REPO}/.fvtt-dependencies.yml | xargs -I {} -d '\n' \
curl -sL "https://${INSTANCE_NAME}.fvtt.sigil.info/setup"  \
-X 'POST' \
-H 'Content-Type: application/json' \
-H 'Pragma: no-cache' \
-H 'Accept: */*' \
--data-binary '{"action":"installPackage","type":"module","manifest":"'"{}"'"}'

yq '.dependencies[] | select( .method == "git-public" ) | select( .type == "system" ) | .url' ${LOCAL_REPO}/.fvtt-dependencies.yml | \
xargs -I {} -d '\n' \
sh -c 'x="{}"; x="${x##*/}"; x="${x%.git}"; [[ -d /fvtt/dependencies/$x ]] || git clone "{}" "/fvtt/dependencies/$x"; git -C /fvtt/dependencies/$x pull; ln -s "/fvtt/dependencies/$x" "${INSTANCE_DIR}/Data/systems/$x"' sh

yq '.dependencies[] | select( .method == "git-public" ) | select( .type == "module" ) | .url' ${LOCAL_REPO}/.fvtt-dependencies.yml | \
xargs -I {} -d '\n' \
sh -c 'x="{}"; x="${x##*/}"; x="${x%.git}"; [[ -d /fvtt/dependencies/$x ]] || git clone "{}" "/fvtt/dependencies/$x"; git -C /fvtt/dependencies/$x pull; ln -s "/fvtt/dependencies/$x" "${INSTANCE_DIR}/Data/modules/$x"' sh

yq '.dependencies[] | select( .method == "git-sigil" ) | select( .type == "system" ) | .path' ${LOCAL_REPO}/.fvtt-dependencies.yml | \
xargs -I {} -d '\n' \
sh -c 'x="{}"; x="${x##*/}"; x="${x%.git}"; [[ -d /fvtt/dependencies/$x ]] || git clone "https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_URL#https://}{}" /fvtt/dependencies/$x; git -C /fvtt/dependencies/$x remote set-url origin "{}" ; git -C /fvtt/dependencies/$x pull; ln -sf /fvtt/dependencies/$x ${INSTANCE_DIR}/Data/systems/$x' sh

yq '.dependencies[] | select( .method == "git-sigil" ) | select( .type == "module" ) | .path' ${LOCAL_REPO}/.fvtt-dependencies.yml | \
xargs -I {} -d '\n' \
sh -c 'x="{}"; x="${x##*/}"; x="${x%.git}"; [[ -d /fvtt/dependencies/$x ]] || git clone "https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_URL#https://}{}" /fvtt/dependencies/$x; git -C /fvtt/dependencies/$x remote set-url origin "{}" ; git -C /fvtt/dependencies/$x pull; ln -sf /fvtt/dependencies/$x ${INSTANCE_DIR}/Data/modules/$x' sh

sleep 60

if [[ ! -d ${INSTANCE_DIR}/Data/worlds/${INSTANCE_NAME} ]];
then
  # rm -rf ${INSTANCE_DIR}/worlds/${INSTANCE_NAME}
  curl -sL "https://${INSTANCE_NAME}.fvtt.sigil.info/setup"  \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'Pragma: no-cache' \
  -H 'Accept: */*' \
  --data-binary '{"title":"'"${INSTANCE_NAME}"'","name":"'"${INSTANCE_NAME}"'","system":"'"${FVTT_SYSTEM_ID}"'","background":"","nextSession":null,"description":"","action":"createWorld"}'
  sleep 5
fi

pm2 stop ${INSTANCE_NAME}

ln -sf ${LOCAL_REPO}/ ${INSTANCE_DIR}/Data/modules/${CI_PROJECT_NAME}

sed -e 's/{{NAME}}/'"${INSTANCE_NAME}"'/g' -e 's/{{WORLD}}/'"${INSTANCE_NAME}"'/g' -e 's/{{PORT}}/'"${INSTANCE_PORT}"'/g' /fvtt/instances/.template > ${INSTANCE_DIR}Config/options.json

echo "a7066028595b3d615a03fddc4e825a4b391eda8a3652b2d8c01d6c21621bab0668f49a00f111bc3a60f23540677f30010c7d6a860cb734d3e6fe4467b096d1aa" > ${INSTANCE_DIR}/Config/admin.txt

pm2 start ${INSTANCE_NAME}