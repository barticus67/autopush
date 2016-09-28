#!/bin/sh

DEBUG="true"

CHANGE_FLAG="false"
REPO_DIR="/u01"
REPO_NAME="repo_passwords"
REPO_URL="git@github.com:barticus67/autopush.git"
TARGET_FILE="common.yaml"
USER_LIST="root sysmgr"

# Get current Stash values

rm -rf ${REPO_DIR}/${REPO_NAME}
cd ${REPO_DIR}

if [ "${DEBUG}" = "true" ]
then
  git clone ${REPO_URL} ${REPO_NAME}
else
  git clone ${REPO_URL} ${REPO_NAME} >/dev/null 2>&1
fi

cd ${REPO_DIR}/${REPO_NAME}

if [ "${DEBUG}" = "true" ]
then
  echo "USER_LIST='${USER_LIST}'"
fi

# Process each user in turn

for THIS_USER in ${USER_LIST}
do
  if [ "${DEBUG}" = "true" ]
  then
    echo "Checking ${THIS_USER}"
  fi

  CURRENT_PASSWD="`grep ^${THIS_USER}: /etc/shadow.bart | cut -d: -f2`"
  REPO_PASSWD="`grep ^profile::${THIS_USER}: ${TARGET_FILE} | awk '{print $2}' | sed s/\'//g`"

  if [ "${DEBUG}" = "true" ]
  then
    echo "CURRENT_PASSWD='${CURRENT_PASSWD}'"
    echo "REPO_PASSWD='${REPO_PASSWD}'"
  fi

  if [ "${REPO_PASSWD}" != "${CURRENT_PASSWD}" ]
  then
    if [ "${DEBUG}" = "true" ]
    then
      echo "Changing password for ${THIS_USER} to ${CURRENT_PASSWD}"
    fi

    CHANGE_FLAG="true"
    sed -i "s~^profile::${THIS_USER}: '.*'~profile::${THIS_USER}: '${CURRENT_PASSWD}'~" ${REPO_DIR}/${REPO_NAME}/${TARGET_FILE}
  fi
done

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

exit 0
