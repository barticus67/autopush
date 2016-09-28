#!/bin/sh

DEBUG="true"

CHANGE_FLAG="false"
REPO_DIR="/tmp"
REPO_NAME="repo_passwords"
REPO_URL="git@github.com:barticus67/autopush.git"
TARGET_FILE="common.yaml"
USER_LIST="root sysmgr"

# Display parameters

if [ "${DEBUG}" = "true" ]
then
  echo "REPO_DIR='${REPO_DIR}'"
  echo "REPO_NAME='${REPO_NAME}'"
  echo "REPO_URL='${REPO_URL}'"
  echo "TARGET_FILE='${TARGET_FILE}'"
  echo "USER_LIST='${USER_LIST}'"
fi

# Clone repository to get current passwords

rm -rf ${REPO_DIR}/${REPO_NAME}

cd ${REPO_DIR}

if [ "${DEBUG}" = "true" ]
then
  git clone ${REPO_URL} ${REPO_NAME}
else
  git clone ${REPO_URL} ${REPO_NAME} >/dev/null 2>&1
fi

# Process each user in turn

cd ${REPO_DIR}/${REPO_NAME}

for THIS_USER in ${USER_LIST}
do
  if [ "${DEBUG}" = "true" ]
  then
    echo "Checking ${THIS_USER}"
  fi

  # Find the current password for this user

  CURRENT_PASSWD="`grep ^${THIS_USER}: /etc/shadow.bart | cut -d: -f2`"

  # Find the repository password for this user

  REPO_PASSWD="`grep ^profile::${THIS_USER}: ${TARGET_FILE} | awk '{print $2}' | sed s/\'//g`"

  if [ "${DEBUG}" = "true" ]
  then
    echo "CURRENT_PASSWD='${CURRENT_PASSWD}'"
    echo "REPO_PASSWD='${REPO_PASSWD}'"
  fi

  # Only update the repository file if the password has changed

  if [ "${REPO_PASSWD}" != "${CURRENT_PASSWD}" ]
  then
    if [ "${DEBUG}" = "true" ]
    then
      echo "Changing password for ${THIS_USER} to ${CURRENT_PASSWD}"
    fi

    sed -i "s~^profile::${THIS_USER}: '.*'~profile::${THIS_USER}: '${CURRENT_PASSWD}'~" ${REPO_DIR}/${REPO_NAME}/${TARGET_FILE}

    # Set a flag to trigger a git add, commit & push

    CHANGE_FLAG="true"
  fi
done

# If the change flag was set, trigger a git add, commit & push

if [ "${CHANGE_FLAG}" = "true" ]
then
  if [ "${DEBUG}" = "true" ]
  then
    echo "Pushing changes"
  fi

  git add ${REPO_DIR}/${REPO_NAME}
  git commit -m "Password change for `date +%B-%Y`"
  git push origin
fi

# Clean up local clone

rm -rf ${REPO_DIR}/${REPO_NAME}

exit 0
