# Color codes
MAGE="\033[35m"
DEF="\033[0m"

echo -e $MAGE🔥💻 Starting Firebase emulators$DEF
firebase emulators:exec "sh run_tests.sh"