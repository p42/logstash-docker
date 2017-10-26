#!/usr/bin/with-contenv /bin/sh

echo "Directory received is ${1}"
# DIR="/tmp"
# $1 is the working directory
# $2 directory where we'll clone
# $3 is the repo url

# Takes a path, relative or absolute and ensures that it exists
# Wich means that it creates any directories needed so that the full
# supplied structure exists upon exit.
ensure_directory() {
    DIRECTORY_PATH=$1
    echo "${DIRECTORY_PATH}"
    if [ -z DIRECTORY_PATH ]; then
        echo "No path recevied, nothing to ensure."
    else
        IFS="/" read -r -a array <<< "$DIRECTORY_PATH"
        WD=""
        # If the first element of the array is a blank space then we know we are were supplied
        # an absolute path. Set our WD parameter to first be '/'.
        if [ -z ${array[0]} ]; then
            echo "An absolute path was supplied."
            CHANGE="/"
        else
            echo "A relative path was supplied"
        fi
        # We need to handle the first element of the array intelligently so we don't fail out later in our process.
        for element in "${array[@]}"
        do
            if [ ! -z $element ]; then
                CHANGE=$CHANGE$element
                echo "Current working directory is $(pwd)"
                echo "Testing path argument ${CHANGE}"
                # We're assuming that an absolute path was supplied.
                if [ -d $CHANGE ]; then
                    echo "Directory exists for $(pwd)/${CHANGE}"
                else
                    echo "No directory at $(pwd)/${element}. Creating."
                    mkdir $CHANGE
                fi
                cd $CHANGE
                CHANGE=""
            fi
        done

    fi
}
if [ $# -eq 0 ]; then
    echo "No directory argument supplied. Using current directory."
elif [ ! -d "$1" ]; then
    echo "The supplied directory ${1} does not exist"
    exit 0
else
    echo "$1 exists. Changing working directory."
    cd $1
    pwd
fi

#Run our install script to ensure that git is installed and configured.
# bash /scripts/git_install_setup.sh

#cd $1
# Stage 1.
        # Check for existence of key files.
# if [ -e /Users/bcone/Development/logstash-docker/container_files/scripts/assets/id_rsa.pub ]; then
if [ -e /scripts/assets/id_rsa.pub ]; then
    if [ ! -d ~/.ssh ]; then
        echo ".ssh directory does not exist. creating."
        mkdir ~/.ssh
        # Force in git.ops.esu10.org into the known hosts file.
        cat >> ~/.ssh/known_hosts <<EOF 
git.ops.esu10.org,204.234.24.180 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGXqTFGIttY4u/LT49IWhWKHQu31DgfIVYxtMxPMGd2VPk/YcENc/gy3dZmFf6JRnbzUrLwbFDbp4EkRcDW26AU=
EOF
    fi
    echo "copying id_rsa.pub to .ssh directory."
    cp /scripts/assets/id_rsa.pub ~/.ssh/
else
    echo "Pub Key not found. Script cannot complete."
    exit 0
fi
# Check for Private Key
echo "Pub key file located. Checking for Private Key"
if [ -e /run/secrets/id_rsa ]; then
    echo "Private key file located. Yay, script can continue."
    cp /run/secrets/id_rsa ~/.ssh/
else
    echo "Private key not found. Script cannot continue."
    exit 0
fi

if [ -d ${LOGSTASH_DIR}/.git ]; then
    # If the .git repo exists then this is not the first time that this script has run.
    # and our only job is to pull down any changes that might exist from the repo.
    echo "Git repo exists in ${LOGSTASH_DIR} directory"
    cd ${LOGSTASH_DIR}
    git pull origin master
    # git add . --all
    # git commit -m "Nightly Commit for $(date)"
else
    # There is no git directory so we assume this is the first time this script has run.
    # We need to do some initial setup.
    # 1. Set up pub/private keys. Pub key is part of this repository; Pri key is assumed to be mounted 
    #     through rancher as secret file named id_rsa and available at the rancher default.
    # 2. Clone the repository down from the provided url.
    # 3. Set up symlinks from the logstash expected location to our repo-provided directories
    #     for config, pipeline, and patterns.
    echo "No git directory in ${LOGSTASH_DIR}. Assuming this is the first time this script has run. Commencing initialization... "
# Stage 2
    if [ ! -z "$LOGSTASH_REPO_GIT_URL" ]; then
        # Repo url no passed through a variable. Check argument 2.
        echo "Repo url passed through a variable."
        echo "${LOGSTASH_REPO_GIT_URL}"
        REPO=$LOGSTASH_REPO_GIT_URL
    elif [ ! -z "$2" ]; then
        echo "Repo url passed through argument."
        REPO=$2
    else
        echo "No git repository supplied, I don't want to assume where this might be so I have to conclude
that I cannot continue in my efforts to set up this infrastructure."
        exit 0
    fi

    echo "git clone ${REPO}"
    git clone ${REPO} ${LOGSTASH_DIR}
    git config --global user.name "Docker Sidekick Container"
    git config --global user.email "bcone+docker_sidekick@esu10.org"

# Stage 3
    # Based on their documentation, Logstash expexts the configuration files (logstash directory)
    # to exist at /usr/share/
fi

#Do Rsync stuff to get config, pipeline, and patterns dirs in correct place
ensure_directory /usr/share/logstash
rsync -v -r ${LOGSTASH_DIR}/ /usr/share/logstash/
