# Color codes
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGE="\033[35m"
DEF="\033[0m"

if [ "$IS_FIREBASE_CLI" = "" ]
then
    echo -e "${RED}ERROR. This file should be run after starting Firebase local emulator.$DEF"
    echo "Run 'sh test.sh' or 'firebase emulators:exec \"sh run_tests.sh\"' instead".
    exit;
fi

password="HardPass@20"
adminEmailAddress="admin@test.com"
emailVerifiedEmail="verf@test.com"

echo -e 🏗 Setting up
node test/firestore_test/lib/setup_tests.js $password $adminEmailAddress $emailVerifiedEmail

if [ "`adb devices`" = "List of devices attached" ]
then
    echo -e "${RED}Skipping Flutter integration tests. \"adb devices\" detected no devices.$DEF"
    echo -e "If you do have an Android device connected, this may be the result of not having 'adb' in your PATH"
else
    echo -e $BLUE💙🧪 Running Flutter integration tests$DEF
    flutter test integration_test --dart-define="password=HardPass@20" --dart-define="adminEmailAddress=admin@test.com" --dart-define="emailVerifiedEmail=verf@test.com"
fi;

echo -e ${YELLOW}🔥🧪 Running Firestore tests${DEF}
cd test/firestore_test
npm test
