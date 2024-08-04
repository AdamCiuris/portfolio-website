set -e # exit if error
# the website runs in a docker container and the target dir is the path that the container makes a volume from

#!/run/current-system/sw/bin/bash
baseDir=$(readlink -f $(dirname $0)) # pwd of shell script
targetDir=~/portfolio-website
echo "This script's parent directory: $baseDir"
echo "Copying to: $targetDir/ ..."
sudo cp -rvf $baseDir/* $targetDir
# rebuild and switch
echo "Finished copying to $targetDir !"