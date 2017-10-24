#!/usr/bin/with-contenv /bin/bash

echo "Directory received is ${1}"
# $1 is the working directory
# $2 directory where we'll clone
# $3 is the repo url

if [ $# -eq 0 ]; then
    echo "No directory argument supplied. Using current directory."
elif [ ! -d "$1" ]; then
    echo "The supplied directory does not exist"
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

if [ -d $2/.git ]; then
    # If the .git repo exists then this is not the first time that this script has run.
    # and our only job is to pull down any changes that might exist from the repo.
    echo "Git repo exists in ${1}/${2} directory"
    cd $2
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
    echo "No git directory in $(pwd). Assuming this is the first time this script has run. Commencing initialization... "
# Stage 2
    if [ ! -z "$LOGSTASH_REPO_GIT_URL" ]; then
        # Repo url no passed through a variable. Check argument 2.
        echo "Repo url passed through a variable."
        echo "${LOGSTASH_REPO_GIT_URL}"
        REPO=$LOGSTASH_REPO_GIT_URL
    elif [ ! -z "$3" ]; then
        echo "Repo url passed through argument."
        REPO=$3
    else
        echo "No git repository supplied, I don't want to assume where this might be so I have to conclude
that I cannot continue in my efforts to set up this infrastructure."
        exit 0
    fi

    echo "git clone ${REPO}"
    git clone ${REPO} $2
    git config --global user.name "Docker Sidekick Container"
    git config --global user.email "bcone+docker_sidekick@esu10.org"

# Stage 3
    # Based on their documentation, Logstash expexts the configuration files (logstash directory)
    # to exist at /usr/share/
fi
