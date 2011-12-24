#!/bin/bash

# find git
GIT=`which git` # /usr/local/bin/git

# default values
RELEASE_DEFAULT="0.1"
REVISION_DEFAULT="nil"

# only try to extract if the project uses git
if [ -d ".git" ]; then

  # find the most recent tag
  RELEASE=`$GIT describe --abbrev=0 --tags 2>/dev/null`
  if [ -z "$RELEASE" ]; then
    # if empty there probably has not been a tag yet
    RELEASE=$RELEASE_DEFAULT
    echo "WARNING: Build is not tagged."
  else
    DESCRIBE=`$GIT describe --dirty --tags 2>/dev/null`
    if [ "$DESCRIBE" != "$RELEASE" ]; then
      echo "WARNING: Build is dirty."
      COMMITS=`git rev-list HEAD --not 0.9 | wc -l | tr -cd '[[:digit:]]'`
      RELEASE="$RELEASE+$COMMITS"
    fi
  fi

  REVISION="`$GIT rev-parse --short HEAD 2>/dev/null`"

  if [ -z "$REVISION" ]; then
    # still empty means there has not been a comit yet
    REVISION=$RELEASE_DEFAULT
  fi
else
  # no git, no revision, default first version
  RELEASE=$RELEASE_DEFAULT
  REVISION=$REVISION_DEFAULT
fi

PREFIX_FILE="$PROJECT_TEMP_DIR/Info.plist.prefix"

# create the file for the preprocessor
if [ -z "$PROJECT_TEMP_DIR" ]; then
  echo "BUILD_RELEASE = $RELEASE"
  echo "BUILD_REVISION = $REVISION"
else
  echo "Created Info.plist prefix file $PREFIX_FILE for $RELEASE $REVISION"
  echo "#define BUILD_RELEASE  $RELEASE"   > "$PREFIX_FILE"
  echo "#define BUILD_REVISION $REVISION" >> "$PREFIX_FILE"
fi

