#!/bin/sh

CHANGE_FLAG="false"
REPO_DIR="/u01"
REPO_NAME="repo_passwords"
REPO_URL="git@github.com:barticus67/autopush.git"
TARGET_FILE="common.yaml"
USER_LIST="root sysmgr"

# Get current Stash values

rm -rf ${REPO_DIR}/${REPO_NAME}
cd ${REPO_DIR}

git clone ${REPO_URL} ${REPO_NAME}

cd ${REPO_DIR}/${REPO_NAME}

echo "USER_LIST='${USER_LIST}'"

# Process each user in turn

for THIS_USER in ${USER_LIST}
do
  echo "Checking ${THIS_USER}"

  CURRENT_PASSWD="`grep ^${THIS_USER}: /etc/shadow.bart | cut -d: -f2`"
  REPO_PASSWD="`grep ^${THIS_USER}: ${TARGET_FILE} | cut -d: -f2`"

  echo "CURRENT_PASSWD='${CURRENT_PASSWD}'"
  echo "REPO_PASSWD='${REPO_PASSWD}'"

  if [ "${REPO_PASSWD}" != "${CURRENT_PASSWD}" ]
  then
    echo "Updating password for ${THIS_USER}"

    CHANGE_FLAG="true"
    sed -i "s~${THIS_USER}:${REPO_PASSWD}~${THIS_USER}:${CURRENT_PASSWD}~" ${REPO_DIR}/${REPO_NAME}/${TARGET_FILE}
  fi
done

if [ "${CHANGE_FLAG}" = "true" ]
then
  echo "Pushing changes"

  git add ${REPO_DIR}/${REPO_NAME}
  git commit -m "Password change for `date +%B-%Y`"
  git push origin
fi

exit 0
