#!/usr/bin/env bash
set -e

if [ "${TRAVIS_TAG}" == "" ]; then
	export VERSION=`git rev-parse --abbrev-ref HEAD`;
else
	export VERSION=${TRAVIS_TAG:1};
fi;
if [ "${VERSION}" == "HEAD" ]; then
	export VERSION=master;
fi;

export BUILD=`git rev-parse HEAD`;

echo ${VERSION} ${BUILD}

make build
make test
make dist
