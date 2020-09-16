#!/bin/bash
RELEASE=${1:-NOPE}
chmod a+x ./release.sh
PARAMS="-g 1.13.5"
if [[ "${RELEASE}" -eq "NOPE" ]]; then
    PARAMS="${PARAMS} -d"
fi
curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- ${PARAMS}
