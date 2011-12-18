#!/bin/sh

# TODO try to find git in various standard locations
GIT=/usr/local/bin/git

RELEASE_DEFAULT="0.1"
REVISION_DEFAULT="nil"

# only try to extract if the project uses git
if [ -d ".git" ]; then

  # find the most recent tag
  RELEASE=`$GIT describe --abbrev=0 2>/dev/null`
  if [ -z "$REVISION" ]; then
    RELEASE=$RELEASE_DEFAULT
  fi

  # first try the convenient 'describe'
  REVISION=`$GIT describe --dirty 2>/dev/null`

  # if empty there probably has not been a tag yet
  if [ -z "$REVISION" ]; then
    # just use the last commit sha then
    REVISION="`$GIT rev-parse --short HEAD 2>/dev/null`"
  fi

  if [ -z "$REVISION" ]; then
    # still empty means there has not been a comit yet
    REVISION=$RELEASE_DEFAULT
  fi
else
  # no git, no revision, default first version
  RELEASE=$RELEASE_DEFAULT
  REVISION=$REVISION_DEFAULT
fi

# create the file for the preprocessor
echo "#define BUILD_RELEASE $RELEASE" > Buildnumber.h
echo "#define BUILD_REVISION $REVISION" >> Buildnumber.h
