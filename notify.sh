#!/usr/bin/env bash

discord.sh \
  --webhook-url="${DISCORD_WEBHOOK}" \
  --username "SIGIL Services CI" \
  --avatar "https://fvtt.sigil.info/logo.png" \
  --title "$1" \
  --description "Commit Message: ${CI_COMMIT_MESSAGE}" \
  --color "0xFF0000" \
  --author "${PRODUCT_NAME}" \
  --url "https://${INSTANCE_NAME}.fvtt.sigil.info" \
  --author-url "https://${INSTANCE_NAME}.fvtt.sigil.info" \
  --author-icon "https://fvtt.sigil.info/foundry_logo.png" \
  --field "SHA;${CI_COMMIT_SHORT_SHA}" \
  --field "Author;${CI_COMMIT_AUTHOR}" \
  --field "Tags;${CI_RUNNER_TAGS}" \
  --field "Job;[${CI_JOB_NAME}](${CI_JOB_URL})" \
  --field "Repository;[Open Repository](${CI_PROJECT_URL})"
  