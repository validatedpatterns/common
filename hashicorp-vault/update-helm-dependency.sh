#!/bin/bash
set -eu

# Get the version of the dependency and then unquote it
REPO="https://helm.releases.hashicorp.com/index.yaml"
NAME="vault"
CHARTDIR="subcharts"
VERSION=$(yq '.dependencies[]|select(.name == "'$NAME'").version' Chart.yaml)
URL=$(curl -L $REPO | yq '.entries.'$NAME'[]|select(.name == "'$NAME'" and .version == "'$VERSION'").urls[]')
TMPD=$(mktemp -d /tmp/$NAME.XXXXX)

trap cleanup SIGINT EXIT

function cleanup {
  echo "Cleaning up"
  if [[ "${TMPD}" =~ /tmp.* ]]; then
    rm -rf "${TMPD}"
  fi
}

# We might have to deal with URLs being multiple, but so far that has not been the case for us
echo "Fetching original upstream chart and decompressing it in 'subcharts/'"
(cd "${TMPD}" && curl -L -o "${NAME}.tgz" "${URL}")
tar xf "${TMPD}/${NAME}.tgz" -C "./${CHARTDIR}"
if [ ! -d "${CHARTDIR}/${NAME}" ]; then
	echo "Chart ${NAME} not found"
	exit 1
fi

pushd "${CHARTDIR}/${NAME}"
for i in ../../local-patches/*.patch; do
	filterdiff "${i}" -p1 -x 'test/*' | patch -p1 --no-backup-if-mismatch
done
popd

helm dependency update .
