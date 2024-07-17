set -e
TAG=ext2-webvm-base-image
DEPLOY_DIR=/home/nyx/GITHUB/portfolio-website/deploy
IMAGE_SIZE=950M
IMAGE_NAME=myimg
SRC_FILE=/home/nyx/GITHUB/portfolio-website/dockerfiles


sudo docker build . --tag $TAG --file $SRC_FILE  --platform=i386
sudo docker run --dns 8.8.8.8 --dns 8.8.4.4 -d $TAG
CONTAINER_ID=$(sudo docker ps -aq)
cmd=$(sudo docker inspect --format='{{json .Config.Cmd}}' $CONTAINER_ID)
entrypoint=$(sudo docker inspect --format='{{json .Config.Entrypoint}}' $CONTAINER_ID)
echo "start if"
if [[ $entrypoint != "null" && $cmd != "null" ]]; then
    CMD=$( sudo docker inspect $CONTAINER_ID | jq --compact-output '.[0].Config.Entrypoint' )
    ARGS=$( sudo docker inspect $CONTAINER_ID | jq --compact-output '.[0].Config.Cmd' )
elif [[ $cmd != "null" ]]; then
    CMD=$( sudo docker inspect $CONTAINER_ID | jq --compact-output '.[0].Config.Cmd[:1]' )
    ARGS=$( sudo docker inspect $CONTAINER_ID | jq --compact-output '.[0].Config.Cmd[1:]' )
else
    CMD=$( sudo docker inspect $CONTAINER_ID | jq --compact-output '.[0].Config.Entrypoint[:1]' )
    ARGS=$( sudo docker inspect $CONTAINER_ID | jq --compact-output '.[0].Config.Entrypoint[1:]' )
fi

echo ENV=$( sudo docker inspect $CONTAINER_ID | jq --compact-output  '.[0].Config.Env' )
echo CWD=$( sudo docker inspect $CONTAINER_ID | jq --compact-output '.[0].Config.WorkingDir' )

# Preallocate space for the ext2 image
sudo fallocate -l $IMAGE_SIZE ${IMAGE_NAME}
# Format to ext2 linux kernel revision 0
sudo mkfs.ext2 -r 0 ${IMAGE_NAME}
# Mount the ext2 image to modify it
sudo mount -o loop -t ext2 ${IMAGE_NAME} /mnt/


# We opt for 'docker cp --archive' over 'docker save' since our focus is solely on the end product rather than individual layers and metadata.
# However, it's important to note that despite being specified in the documentation, the '--archive' flag does not currently preserve uid/gid information when copying files from the container to the host machine.
# Another compelling reason to use 'docker cp' is that it preserves resolv.conf.
#   - name: Export and unpack container filesystem contents into mounted ext2 image.
echo $CONTAINER_ID "wow"
sudo docker cp -a $CONTAINER_ID:/ /mnt/
sudo umount /mnt/

# Move required files for gh-pages deployment to the deployment directory $DEPLOY_DIR.
echo $DEPLOY_DIR "watch this get destroyed"
sudo rm -rf $DEPLOY_DIR
sudo mkdir -p $DEPLOY_DIR
sudo cp -r assets examples xterm favicon.ico index.html login.html network.js scrollbar.css serviceWorker.js tower.ico $DEPLOY_DIR

# Generate image split chunks and .meta file
sudo split $IMAGE_NAME $DEPLOY_DIR/$IMAGE_NAME.c -a 6 -b 128k -x --additional-suffix=.txt
sudo bash -c "stat -c%s $IMAGE_NAME  > $DEPLOY_DIR/$IMAGE_NAME.meta"

# This step updates the default index.html file by performing the following actions:
#   1. Replaces all occurrences of IMAGE_URL with the URL to the image.
#   2. Replaces all occurrences of DEVICE_TYPE to bytes.
#   3. Replace CMD with the Dockerfile entry command.
#   4. Replace args with the Dockerfile CMD / Entrypoint args.
#   5. Replace ENV with the container's environment values.
#   - name: Adjust index.html
sudo sed -i 's#DEVICE_TYPE#"split"#g' $DEPLOY_DIR/index.html
sudo sed -i 's#CMD#${{ CMD }}#g' $DEPLOY_DIR/index.html
sudo sed -i 's#ARGS#${{ ARGS }}#g' $DEPLOY_DIR/index.html
sudo sed -i 's#ENV#${{ ENV }}#g' $DEPLOY_DIR/index.html
sudo sed -i 's#CWD#${{ CWD }}#g' $DEPLOY_DIR/index.html



# We generate index.list files for our httpfs to function properly.
#   - name: make index.list
# shell: bash
# run: |
find $DEPLOY_DIR -type d | while read -r dir;
do
    index_list="$dir/index.list";
    sudo rm -f "$index_list";
    sudo ls "$dir" | sudo tee "$index_list" > /dev/null;
    sudo chmod +rw "$index_list";     
    sudo echo "created $index_list"; 
done

      # Create a gh-pages