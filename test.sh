# Color codes
MAGE="\033[35m"
DEF="\033[0m"

flutter_only=$1
if [ "$flutter_only" = "true" ]
then
    script="sh run_flutter_tests.sh"
    echo "$script"
else
    script="sh run_tests.sh"
fi

echo -e $MAGE🔥💻 Starting Firebase emulators$DEF
firebase emulators:exec "$script"