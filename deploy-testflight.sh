#!/bin/bash

API_TOKEN=`security find-internet-password -s oss.sonatype.org -g 2>&1 | grep acct | sed 's/.*=\"\(.*\)\"/\1/'`
TEAM_TOKEN=`security find-internet-password -s oss.sonatype.org -g 2>&1 | grep password | sed 's/password: \"\(.*\)\"/\1/'`


API_TOKEN=<TestFlight API token here>
TEAM_TOKEN=<TestFlight team token here>
SIGNING_IDENTITY="iPhone Distribution: Development Seed"
PROVISIONING_PROFILE="${HOME}/Library/MobileDevice/Provisioning Profiles/MapBox Ad Hoc.mobileprovision"
#LOG="/tmp/testflight.log"
GROWL="${HOME}/bin/growlnotify -a Xcode -w"

DATE=$( /bin/date +"%Y-%m-%d" )
ARCHIVE=$( /bin/ls -t "${HOME}/Library/Developer/Xcode/Archives/${DATE}" | /usr/bin/grep xcarchive | /usr/bin/sed -n 1p )
DSYM="${HOME}/Library/Developer/Xcode/Archives/${DATE}/${ARCHIVE}/dSYMs/${PRODUCT_NAME}.app.dSYM"
APP="${HOME}/Library/Developer/Xcode/Archives/${DATE}/${ARCHIVE}/Products/Applications/${PRODUCT_NAME}.app"

#/usr/bin/open -a /Applications/Utilities/Console.app $LOG

#echo -n "Creating .ipa for ${PRODUCT_NAME}... " > $LOG
echo "Creating .ipa for ${PRODUCT_NAME}" | ${GROWL}

/bin/rm "/tmp/${PRODUCT_NAME}.ipa"
/usr/bin/xcrun -sdk iphoneos PackageApplication -v "${APP}" -o "/tmp/${PRODUCT_NAME}.ipa" --sign "${SIGNING_IDENTITY}" --embed "${PROVISIONING_PROFILE}"

#echo "done." >> $LOG
echo "Created .ipa for ${PRODUCT_NAME}" | ${GROWL}

#echo -n "Zipping .dSYM for ${PRODUCT_NAME}..." >> $LOG
echo "Zipping .dSYM for ${PRODUCT_NAME}" | ${GROWL}

/bin/rm "/tmp/${PRODUCT_NAME}.dSYM.zip"
/usr/bin/zip -r "/tmp/${PRODUCT_NAME}.dSYM.zip" "${DSYM}"

#echo "done." >> $LOG
echo "Created .dSYM for ${PRODUCT_NAME}" | ${GROWL}

#echo -n "Uploading to TestFlight... " >> $LOG
echo "Uploading to TestFlight" | ${GROWL}

/usr/bin/curl "http://testflightapp.com/api/builds.json" \
  -F file=@"/tmp/${PRODUCT_NAME}.ipa" \
  -F dsym=@"/tmp/${PRODUCT_NAME}.dSYM.zip" \
  -F api_token="${API_TOKEN}" \
  -F team_token="${TEAM_TOKEN}" \
  -F notes="Build uploaded automatically from Xcode."

#echo "done." >> $LOG
echo "Uploaded to TestFlight" | ${GROWL} -s && /usr/bin/open "https://testflightapp.com/dashboard/builds/"