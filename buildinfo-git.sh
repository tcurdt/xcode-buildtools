#!/bin/bash

# find git
GIT=`which git` # /usr/local/bin/git

# default values
RELEASE_DEFAULT="0.1"
REVISION_DEFAULT="0"

# only try to extract if the project uses git
if [ -d ".git" ]; then

  # the most recent tag is the next release
  RELEASE=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 HEAD) 2>/dev/null)
  if [ -z "$RELEASE" ]; then
    RELEASE=$RELEASE_DEFAULT
    echo "WARNING: Build is not tagged."
  fi

  # get the revision
  REVISION="`$GIT rev-parse --short HEAD 2>/dev/null`"
  if [ -z "$REVISION" ]; then
    # still empty means there has not been a comit yet
    REVISION=$REVISION_DEFAULT
  fi

  DESCRIBE=`$GIT describe --dirty --tags 2>/dev/null`
  if [ "$DESCRIBE" != "$RELEASE" ]; then
    if [ -z "$DESCRIBE" ]; then
      COMMITS_SINCE_TAG=
    else
      COMMITS_SINCE_TAG=$(git rev-list HEAD --not "$RELEASE" | wc -l | tr -cd '[[:digit:]]')
    fi
    NOT_COMMITTED=$(git status --porcelain 2>/dev/null| egrep "^(M| M|A| A|??)" | wc -l | tr -cd '[[:digit:]]')
    if [ "${COMMITS_SINCE_TAG}M${NOT_COMMITTED}" != "M0" ]; then
      echo "WARNING: Build is dirty."
      REVISION="$REVISION+${COMMITS_SINCE_TAG}M${NOT_COMMITTED}"
    fi
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

