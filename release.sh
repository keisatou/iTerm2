#!/bin/bash
function RunFromMakefile {
  echo You\'re supposed to use "make release", not run this directly. I\'ll just do it for you.
  sleep 1
  make release
  exit
}

# Usage: SparkleSign testing.xml template.xml
function SparkleSign {
    LENGTH=$(ls -l iTerm2-${NAME}.zip | awk '{print $5}')
    ruby "../../SparkleSigningTools/sign_update.rb" iTerm2-${NAME}.zip $PRIVKEY > /tmp/sig.txt
    SIG=$(cat /tmp/sig.txt)
    DATE=$(date +"%a, %d %b %Y %H:%M:%S %z")
    XML=$1
    TEMPLATE=$2
    cp $SVNDIR/appcasts/${TEMPLATE} /tmp
    cat /tmp/${TEMPLATE} | \
    sed -e "s/%XML%/${XML}/" | \
    sed -e "s/%VER%/${VERSION}/" | \
    sed -e "s/%DATE%/${DATE}/" | \
    sed -e "s/%NAME%/${NAME}/" | \
    sed -e "s/%LENGTH%/$LENGTH/" |
    sed -e "s,%SIG%,${SIG}," > $SVNDIR/appcasts/$1
    cp iTerm2-${NAME}.zip ~/iterm2-website/downloads/beta/
}

echo Num args is $#
[ $# -gt 0 ] || RunFromMakefile
[ "$1" = RanFromMakefile ] || RunFromMakefile

COMPACTDATE=$(date +"%Y%m%d")
VERSION=$(cat version.txt | sed -e "s/%(extra)s/$COMPACTDATE/")
NAME=$(echo $VERSION | sed -e "s/\\./_/g")
SVNDIR=~/iterm2-website
ORIG_DIR=`pwd`

./sign.sh

# Build tmux and move its tar.gz into the Deployment build directory
cd ~/tmux
git checkout master
git pull origin master
make
rm *.o
cd ..
tar cvfz tmux-for-iTerm2-$COMPACTDATE.tar.gz tmux/* tmux/.deps
cd $ORIG_DIR
mv ~/tmux-for-iTerm2-$COMPACTDATE.tar.gz build/Deployment
cd build/Deployment

# Create the zip file
zip -ry iTerm2-${NAME}.zip iTerm.app

# Update the list of changes
vi $SVNDIR/appcasts/testing_changes.txt

# Prepare the sparkle xml file
SparkleSign testing.xml template.xml

############################################################################################
# Begin legacy build
cd "../Leopard Deployment"

MODERN_NAME=$NAME
NAME=$(echo $VERSION | sed -e "s/\\./_/g")-LeopardPPC

# Create the zip file
zip -ry iTerm2-${NAME}.zip iTerm.app

# Prepare the sparkle xml file
SparkleSign legacy_testing.xml legacy_template.xml
# End legacy build
############################################################################################

echo "Go upload iTerm2-${MODERN_NAME}.zip and iTerm2-${NAME}.zip"
echo "Then run:"
echo "git tag v${VERSION}"
echo "git push --tags"
echo "pushd ${SVNDIR} && git commit -am ${VERSION} && git push origin master"
echo "popd"
echo "git commit -am ${VERSION}"
echo "git push origin master"
