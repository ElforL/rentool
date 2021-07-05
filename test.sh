# Color codes
RED="\033[91m"
BLUE="\033[34m"
MAGE="\033[35m"
DEF="\033[0m"

# Flutter
echo -e $BLUE💙🧪 Running Flutter tests$DEF
flutter test

# Firebase
# Firestore
echo -e $MAGE🔥💻 Starting Firebase emulators$DEF
firebase emulators:exec "printf '${RED}🔥🧪 Running Firestore tests${DEF}' && \
                        cd test/firestore_test && \
                        npm test"