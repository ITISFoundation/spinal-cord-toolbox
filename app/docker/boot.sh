#!/bin/sh

INFO="INFO: [$(basename "$0")] "
ERROR="ERROR: [$(basename "$0")] "
WARNING="WARNING: [$(basename "$0")] "

# When starting in legacy boot mode the below directories need to be
# created.
# When booted via dynamic-sidecar these paths are usually mounted
# so crearion will be skipped.
mkdir -p "/home/$SC_USER_NAME/work/inputs"
mkdir -p "/home/$SC_USER_NAME/work/outputs"
mkdir -p "/home/$SC_USER_NAME/work/workspace"

# expect input/output folders to be mounted
stat "${DY_SIDECAR_PATH_INPUTS}" > /dev/null 2>&1 || \
        (echo "$ERROR: You must mount '${DY_SIDECAR_PATH_INPUTS}' to deduce user and group ids" && exit 1)
stat "${DY_SIDECAR_PATH_OUTPUTS}" > /dev/null 2>&1 || \
    (echo "$ERROR: You must mount '${DY_SIDECAR_PATH_OUTPUTS}' to deduce user and group ids" && exit 1)

# NOTE: expects docker run ... -v /path/to/input/folder:${DY_SIDECAR_PATH_INPUTS}
# check input/output folders are owned by the same user
if [ "$(stat -c %u "${DY_SIDECAR_PATH_INPUTS}")" -ne "$(stat -c %u "${DY_SIDECAR_PATH_OUTPUTS}")" ]
then
    echo "$ERROR: '${DY_SIDECAR_PATH_INPUTS}' and '${DY_SIDECAR_PATH_OUTPUTS}' have different user id's. not allowed" && exit 1
fi
# check input/outputfolders are owned by the same group
if [ "$(stat -c %g "${DY_SIDECAR_PATH_INPUTS}")" -ne "$(stat -c %g "${DY_SIDECAR_PATH_OUTPUTS}")" ]
then
    echo "$ERROR: '${DY_SIDECAR_PATH_INPUTS}' and '${DY_SIDECAR_PATH_OUTPUTS}' have different group id's. not allowed" && exit 1
fi

echo "$INFO listing inputs folder"
ls -lah "${DY_SIDECAR_PATH_INPUTS}"
echo "$INFO listing outputs folder"
ls -lah "${DY_SIDECAR_PATH_OUTPUTS}"

echo "$INFO setting correct user id/group id..."
HOST_USERID=$(stat -c %u "${DY_SIDECAR_PATH_INPUTS}")
HOST_GROUPID=$(stat -c %g "${DY_SIDECAR_PATH_INPUTS}")
CONTAINER_GROUPNAME=$(getent group | grep "${HOST_GROUPID}" | cut --delimiter=: --fields=1 || echo "")
if [ "$HOST_USERID" -eq 0 ]
then
    echo "$WARNING: Folder mounted owned by root user... adding $SC_USER_NAME to root..."
    addgroup "$SC_USER_NAME" root
else
    echo "$INFO Folder mounted owned by user $HOST_USERID:$HOST_GROUPID-'$CONTAINER_GROUPNAME'..."
    # take host's credentials in $SC_USER_NAME
    if [ -z "$CONTAINER_GROUPNAME" ]
    then
        echo "$INFO Creating new group my$SC_USER_NAME"
        CONTAINER_GROUPNAME="my$SC_USER_NAME"
        addgroup --gid "$HOST_GROUPID" "$CONTAINER_GROUPNAME"
    else
        echo "$INFO group already exists"
    fi

    echo "$INFO changing $SC_USER_NAME $SC_USER_ID:$SC_USER_ID to $HOST_USERID:$HOST_GROUPID"
    # in alpine there is no such thing as usermod... so we delete the user and re-create it as part of $CONTAINER_GROUPNAME
    deluser "$SC_USER_NAME" > /dev/null 2>&1
    adduser --uid "$HOST_USERID" --gid "$HOST_GROUPID" --system --no-create-home --disabled-login --disabled-password --shell /bin/sh "$SC_USER_NAME"

    echo "$INFO Changing group properties of files around from $SC_USER_ID to group $CONTAINER_GROUPNAME"
    find / -prune -o -group "$SC_USER_ID" -print
    find / -prune -o -group "$SC_USER_ID" -exec chgrp -h "$CONTAINER_GROUPNAME" {} \;
    # change user property of files already around
    echo "$INFO Changing ownership properties of files around from $SC_USER_ID to group $CONTAINER_GROUPNAME"
    find / -prune -o -user "$SC_USER_ID" -exec chown -h "$SC_USER_NAME" {} \;
    find / -prune -o -user "$SC_USER_ID" -print
fi

echo "$INFO Changing permission in /home/$SC_USER_NAME folder ..."
chown -R "$SC_USER_NAME":"$CONTAINER_GROUPNAME" "/home/$SC_USER_NAME"
echo "$INFO Changing permission in /dev/stdout folder ..."
chown "$SC_USER_NAME":"$CONTAINER_GROUPNAME" /dev/stdout 

exec gosu "$SC_USER_NAME" supervisord