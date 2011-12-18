#!/bin/sh

GIT=/usr/local/bin/git
if [ -d ".git" ]; then
  VERSION=`$GIT describe --dirty 2>/dev/null`

  if [ -z "$VERSION" ]; then
    VERSION="`$GIT rev-parse --short HEAD 2>/dev/null`"
  fi

  if [ -z "$VERSION" ]; then
    VERSION="nil"
  fi
else
  VERSION="nil"
fi

if [ "$VERSION" != "nil" ]; then
  VERSION="@\"$VERSION\""
fi

echo "#define GIT_VERSION $VERSION" > Version.h