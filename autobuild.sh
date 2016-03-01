#!/bin/sh

#  build-imkit.sh
#  RongIMKit
#
#  Created by xugang on 4/8/15.
#  Copyright (c) 2015 RongCloud. All rights reserved.

configuration="Release"
DEV_FLAG=""
VER_FLAG=""
VOIP_FLAG=""

for i in "$@"
do
PFLAG=`echo $i|cut -b1-2`
PPARAM=`echo $i|cut -b3-`
if [ $PFLAG == "-b" ]
then
DEV_FLAG=$PPARAM
elif [ $PFLAG == "-v" ]
then
VER_FLAG=$PPARAM
elif [ $PFLAG == "-o" ]
then
VOIP_FLAG=$PPARAM
fi
done


sed -i ""  -e '/CFBundleShortVersionString/{n;s/[0-9]\.[0-9]\.[0-9]\{1,2\}/'"$VER_FLAG"'/; }' ./RongIMKit/Info.plist

if [ ${DEV_FLAG} == "debug" ]
then
configuration="Debug"
else
configuration="Release"
fi

if [ "${VOIP_FLAG}" = "no" ]
then
sed -i '' -e '/RC_VOIP_ENABLE/s/1/0/g' ./RongIMKit/PrefixHeader.pch
sed -i '' -e '/libiOS_VoipLib\.a/d' ./RongIMKit.xcodeproj/project.pbxproj

else
echo "have voip"
fi

PROJECT_NAME="RongIMKit.xcodeproj"
targetName="RongIMKit"
TARGET_DECIVE="iphoneos"
TARGET_I386="iphonesimulator"

xcodebuild clean -configuration $configuration -sdk $TARGET_DECIVE
xcodebuild clean -configuration $configuration -sdk $TARGET_I386

echo "***开始build iphoneos文件***"
xcodebuild OTHER_CFLAGS="-fembed-bitcode" -project ${PROJECT_NAME} -target "$targetName" -configuration $configuration  -sdk $TARGET_DECIVE build

echo "***开始build iphonesimulator文件***"
xcodebuild OTHER_CFLAGS="-fembed-bitcode" -project ${PROJECT_NAME} -target "$targetName" -configuration $configuration  -sdk $TARGET_I386 build

echo "***完成Build ${targetName}静态库${configuration}****"
