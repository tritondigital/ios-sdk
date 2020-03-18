#!/bin/bash

PACKAGE_NAME="triton-ios-sdk"
VERSION_FILE="version.properties"

SDK_VERSION="$1"
if [ -z "$SDK_VERSION" ]; then
    echo "error: You must supply a version number for the SDK."
    exit 1
fi

echo "info: Building sdk version $SDK_VERSION"
#xcodebuild -scheme TritonPlayerSDKStatic-Universal OTHER_CFLAGS="-fembed-bitcode" SYMROOT="Framework" -configuration Release -UseModernBuildSystem=NO
xcodebuild -scheme TritonPlayerSDKStatic-Universal SYMROOT="Framework" -configuration Release -UseModernBuildSystem=YES

echo "info: Generating doc"
xcodebuild -scheme Documentation SYMROOT="Framework" -configuration Release -UseModernBuildSystem=YES SUPPORTS_MACCATALYST=NO

echo "info: Generating SDK package"
echo "info: Copy Framework"
cp -R "Framework/Release-iphoneos/TritonPlayerSDK.framework" "tritonplayer-sample-app"

echo "info: Copy Documentation"
cp -R "Framework/Documentation" "tritonplayer-sample-app/Documentation"

echo "info: Copy README"
cp "README.txt" "tritonplayer-sample-app"

echo "info: creating version file $VERSION_FILE"
cat > "tritonplayer-sample-app/$VERSION_FILE" << EOF
version=$SDK_VERSION
commit=$(git rev-parse HEAD)
EOF

echo "info: Rename folder for packaging"
cp -R "tritonplayer-sample-app" "$PACKAGE_NAME-$SDK_VERSION"

echo "info: Delete dev version of the xcodeproj file"
rm -rf "$PACKAGE_NAME-$SDK_VERSION/tritonplayer-sample-app-dev.xcodeproj"

echo "info: Generated file: $PWD/$PACKAGE_NAME-$SDK_VERSION.zip"
zip -r -X "$PACKAGE_NAME-$SDK_VERSION.zip" "$PACKAGE_NAME-$SDK_VERSION"

echo "cleaning sample app"
rm -f "tritonplayer-sample-app/README.txt"
rm -f "tritonplayer-sample-app/version.properties"
rm -rf "tritonplayer-sample-app/TritonPlayerSDK.framework"


