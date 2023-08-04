#!/bin/bash
# Shell script to create a .app file from a .jar
# FOR ADITIONAL FILES, MUST IMPORT MANUALLY TO .app/Contents/Java
WORK_DIR=$(pwd)
ICNS_DEFAULT=$(realpath $(dirname "$0")/default.icns)
# print usage message
usage() {
  if [ "$1" != "" ]; then echo "Error: $1"; fi
  echo "Usage: $(basename $0) [-h] [-a app_name] [-b bundle_name] [-j jar_path] [-i icns_path] [-o output_path] [-v java_version] [app_arguments...]"
  echo "Creates a .app file for MacOS from a jar file"
  echo "Where:"
  echo "  app_name     - name of the .app without the extension"
  echo "  bundle_name  - name of the .app bundler identifier"
  echo "                 default: 'com.jar2app.app_name'"
  echo "  jar_path     - absolute path for the .jar file"
  echo "  icns_path    - absolute path for the .icns file"
  echo "                 default: '$ICNS_DEFAULT'"
  echo "  output_path  - absolute directory for the generated .app"
  echo "                 default: '$WORK_DIR'"
  echo "  java_version - required java runtime version"
  echo "                 eg: '1.8', '1.8*', '1.8+', '11*', '11.0+'"
  echo "                 default: do no check for java runtime version"
  if [ "$1" != "" ]; then exit 254; else exit 0; fi
}
# check arguments validity
check_app_name() {
    if [ "$1" == "" ]; then cmd=echo; else cmd=$1; fi
    if [[ ! "$APP_NAME" =~ ^[^/]+$ ]]; then
        $cmd "Error: invalid app name '$APP_NAME'!"
        APP_NAME=
        return 1
    fi
    check_bundle_name
}
check_bundle_name() {
    if [ "$1" == "" ]; then cmd=echo; else cmd=$1; fi
    if [[ "$APP_NAME" != "" && "$APP_BUNDLE" = "" ]]; then
        APP_BUNDLE="com.jar2app.$APP_NAME";
        return 0
    fi
    if [[ ! "$APP_BUNDLE" =~ ^([\w\-_]+\.)+[\w\-_]+$ ]]; then
        $cmd "Error: invalid app bundle identifier '$APP_BUNDLE'!"
        APP_BUNDLE=
        return 1
    fi
}
check_app_path() {
    if [ "$1" == "" ]; then cmd=echo; else cmd=$1; fi
    if [[ "$APP_PATH" = "" ]]; then
        APP_PATH="$WORK_DIR"
        return 0
    fi
    if [[ ! -d "$APP_PATH" ]]; then
        $cmd "Error: invalid app output path '$APP_PATH'!"
        APP_PATH=
        return 1
    fi
}
check_jar_path() {
    if [ "$1" == "" ]; then cmd=echo; else cmd=$1; fi
    if [[ ${JAR_PATH: -4} != ".jar" || ! -f "$JAR_PATH" ]]; then
        $cmd "Error: invalid jar file '$JAR_PATH'!"
        JAR_PATH=
        return 1
    fi
}
check_icns_path() {
    if [ "$1" == "" ]; then cmd=echo; else cmd=$1; fi
    if [[ "$ICNS_PATH" = "" ]]; then
        ICNS_PATH="$ICNS_DEFAULT"
        return 0
    fi
    if [[ ${ICNS_PATH: -5} != ".icns" || ! -f "$ICNS_PATH" ]]; then
        $cmd "Error: invalid icns file '$ICNS_PATH'!"
        ICNS_PATH=
        return 1
    fi
}
check_jvm_version() {
    if [ "$1" == "" ]; then cmd=echo; else cmd=$1; fi
    if [[ "$JVM_VERSION" = "" ]]; then
        return 0
    fi
    if [[ ! "$JVM_VERSION" =~ ^(9|1[0-9])(-ea|[*+]|(\.[0-9]+){1,2}[*+]?)?$ && ! "$JVM_VERSION" =~ ^1\.[4-8](\.[0-9]+)?(\.0_[0-9]+)?[*+]?$ ]]; then
        $cmd "Error: invalid jvm runtime version '$JVM_VERSION'!"
        JVM_VERSION=
        return 1
    fi
}
# parse command line options
while getopts :ha:b:j:i:o:v: OPTCMD; do
  if [ "$OPTCMD" = "?" ] && [ "$OPTARG" = "-" ]; then break; fi
  if [ "${OPTARG:0:1}" = "-" ]; then OPTARG=$OPTCMD; OPTCMD=":"; fi
  case "$OPTCMD" in
    h) usage ;;
    a) APP_NAME="$OPTARG" && check_app_name usage ;;
    b) APP_BUNDLE="$OPTARG" && check_bundle_name usage ;;
    o) APP_PATH="$OPTARG" && check_app_path usage ;;
    j) JAR_PATH="$OPTARG" && check_jar_path usage ;;
    i) ICNS_PATH="$OPTARG" && check_icns_path usage ;;
    v) JVM_VERSION="$OPTARG" && check_jvm_version usage ;;
    :) usage "option '-$OPTARG' requires an argument!" ;;
    ?) usage "option '-$OPTARG' is illegal!" ;;
  esac
done
shift $((OPTIND-1))
APP_ARGS="$@"
## input arguments if not specified
while [[ "$APP_NAME" = "" ]]; do
    echo "Please input the name of the .app (without the extension): "
    read APP_NAME
    check_app_name
done
while [[ "$APP_PATH" = "" ]]; do
    echo "Please input the absolute directory for the .app (blank for '$WORK_DIR'): "
    read APP_PATH
    check_app_path
done
while [[ "$JAR_PATH" = "" ]]; do
    echo "Please input the absolute path for the .jar file: "
    read JAR_PATH
    check_jar_path
done
while [[ "$ICNS_PATH" = "" ]]; do
    echo "Please input the absolute path for the .icns file (blank for '$ICNS_DEFAULT'): "
    read ICNS_PATH
    check_icns_path
done
while [[ "$JVM_VERSION" = "" ]]; do
    echo "Please input the required java runtime version (blank for no check): "
    read JVM_VERSION
    check_jvm_version && break
done
# show arguments
echo "Start to create .app file..."
echo "[.app name]:    $APP_NAME"
echo "[.app bundle]:  $APP_BUNDLE"
echo "[.jar path]:    $JAR_PATH"
echo "[.icns path]:   $ICNS_PATH"
echo "[Java version]: $JVM_VERSION"
echo "[Output path]:  $APP_PATH"
echo "[Arguments]:    $APP_ARGS"
# creates directory structure
echo "Creating app directory structure in '$APP_PATH'..."
APP_BASE="$APP_PATH/$APP_NAME.app/Contents"
mkdir -p "$APP_BASE/Java" "$APP_BASE/MacOS" "$APP_BASE/Resources"
if [ "$?" -ne 0 ]; then
    echo "Error: make directory structure in '$APP_PATH' failed!"
    exit 1
fi
# parse main class from .jar file
echo "6. Parsing main class from jar file '$JAR_PATH'..."
MAINCLASS=$(unzip -qc "$JAR_PATH" META-INF/MANIFEST.MF | grep "Main-Class: *" | sed "s/Main-Class: //" | tr -d '[:space:]')
if [[ "$MAINCLASS" = "" ]]; then
    echo "Error: parse main class from file '$JAR_PATH' failed!"
    exit 2
fi
# downloading universalJavaApplicationStub file
echo "Downloading universalJavaApplicationStub..."
curl https://raw.githubusercontent.com/tofi86/universalJavaApplicationStub/master/src/universalJavaApplicationStub -sLo "$APP_BASE/MacOS/universalJavaApplicationStub"
if [ "$?" -ne 0 ]; then
    echo "Error: download universalJavaApplicationStub from github failed!"
    exit 3
fi
# copy jar and icns file
echo "Copying .jar and .icns file to '$APP_PATH'..."
chmod a+x "$APP_BASE/MacOS/universalJavaApplicationStub"
cp "$JAR_PATH" "$APP_BASE/Java/"
cp "$ICNS_PATH" "$APP_BASE/Resources/$APP_NAME.icns"
# write Info.plist file
echo "Writing Info.plist file to '$APP_PATH'..."
touch $APP_BASE//Info.plist
echo "
<?xml version=1.0 encoding=UTF-8?>
<!DOCTYPE \"-//Apple Computer//DTD PLIST 1.0//EN http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=1.0>
    <dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleExecutable</key>
    <string>universalJavaApplicationStub</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$APP_BUNDLE</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>8.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <string>True</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.1</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>1.0.1</string>
    <key>JVMMainClassName</key>
    <string>$MAINCLASS</string>
    <key>JVMVersion</key>
    <string>$JVM_VERSION</string>
    <key>JVMOptions</key>
    <array>
        <string>-Duser.dir=\$APP_ROOT/Contents</string>
        <string>-Xdock:name=$APP_NAME</string>
    </array>
    <key>JVMArguments</key>
    <array>
    $(for i in $APP_ARGS; do echo "<string>$i</string>"; done)
    </array>
    </dict>
</plist>
" > $APP_BASE/Info.plist

echo "Complete..."
