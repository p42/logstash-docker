#!/usr/bin/with-contenv /bin/sh

##################################################################
# This script does some moderately useful things, most notably   #
# is that it is configured to work in a sidekick container to    #
# start, pull down from a git repo, quit.                        #
#                                                                #
# All configuration directives are expected to be available as   #
# variables. You can pass them in as arguments to the script if  #
# you are calling this script explicitly but preference is given #
# to environment variables.                                      #
##################################################################

#############################################################################################
# Expected Variables:                                                                       #
#   If you are passing variables as command arguments, they should be in the order below    #
# 1) WORKING_DIR - REQUIRED - the directory in which you want the script to execute.        #
# 2) GIT_REPO_DIR - OPTIONAL - Directory where you want to install the repo, if you want a  #
#   folder other than the repo name.                                                        #
# 3) GIT_REPO_URL - REQUIRED - The url of the repo which you will be cloning.               #
# 4) GIT_REPO_BRANCH - OPTIONAL, defaults to Master Branch you want to checkout.            #
# 5) DEPLOY_PUB_KEY - REQUIRED, allows placement of pub key.                                #
# 6) DEPLOY_PRI_KEY_LOCATION - OPTIONAL - defaults to /run/secrets from Rancher config.     #
# 7) KNOWN_HOSTS - REQUIRED - host identity of the git repo server.                         #
# 8) COPY_SOME_FILES - OPTIONAL                                                             #
# 9) COPY_SOME_FILES_DST - REQUIRED if setting COPY_SOME_FILES. The destination path        #
#############################################################################################

# Takes a path, relative or absolute and ensures that it exists
# Wich means that it creates any directories needed so that the full
# supplied structure exists upon exit.

# As it turns out, you can do all of this using mkdir -p. Leaving this script here because I like it.
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

##########################################################################
# Let's handle the fail conditions first and save doing them later.      #
# This way, if we get past this section of the script then we know that  #
# everything is in place as expected. Fail-able conditions are:          #
# * WORKING_DIR not supplied                                             #
# * DEPLOY_PUB_KEY not supplied                                          #
# * GIT_REPO_URL not supplied                                            #
# * Private Key not exists                                               #
##########################################################################
DEPLOY_PUB_KEY=${DEPLOY_PUB_KEY:=$5}

GIT_REPO_URL=${GIT_REPO_URL:=$3}

DEPLOY_PRI_KEY_LOCATION=${DEPLOY_PRI_KEY_LOCATION:=$6}

KNOWN_HOSTS=${KNOWN_HOSTS:=$7}

# Some debugging things - write all variables out.

# echo "WORKING_DIR: ${WORKING_DIR}"
# echo "GIT_REPO_DIR: ${GIT_REPO_DIR}"
# echo "GIT_REPO_URL: ${GIT_REPO_URL}"
# echo "DEPLOY_PUB_KEY: ${DEPLOY_PUB_KEY}"
# echo "DEPLOY_PRI_KEY_LOCATION: ${DEPLOY_PRI_KEY_LOCATION}"


# if [[ ${DOTS} -lt 1 ]]
# then
#   echo 'The hostname you entered does not appear to be a valid FQDN, aborting!'
#   exit 1
# fi
if [ -z "$DEPLOY_PUB_KEY" ]; then
    echo "You did not supply a value for the public key. Any value will do at this point
  of the script but you should know that an invalid key will make you fail later."
    exit 0
elif [ -z "$GIT_REPO_URL" ]; then
    echo "You did not supply a git repo. I cannot clone a repo without an endpoint and I'm just
  a lowly bash sript and don't have the ability to infer what you might have intended."
    exit 0
elif [ ! -e "${DEPLOY_PRI_KEY_LOCATION}/id_rsa" ]; then 
    echo "We could not find a private key - assuming filename of \"id_rsa\" - at the supplied path. I'm sure you're aware,
  but without a private key, asynchronous cryptography cannot take place. Therefore, this script must exit."
    exit 0
elif [ -z "$KNOWN_HOSTS" ]; then
    echo "I've been taught not to talk to strangers which means that I clone repos from servers I don't know.
  Please populate my known_hosts file by using the KNOWN_HOSTS variable or use argument 7 as a command arg."
  exit 0
fi

#1. Determine the working directory, first through environment, then through argument, fail to current dir.
WORKING_DIR=${WORKING_DIR:=$1}
echo "Working directory is ${WORKING_DIR}."
if [ ! -z "$WORKING_DIR" ]; then
    echo "We fell into the if case"
    echo "Changing directories to ${WORKING_DIR}";
    if [ ! -d ${WORKING_DIR} ]; then
        echo ""
        echo "The directory you specified does not exist so I am creating it. Please plan better next time."
        echo ""
        mkdir -p ${WORKING_DIR}
    fi
    cd $WORKING_DIR
    echo "As proof that we changed directories, here is the current working direcory: $(pwd)."
else
    echo "No directory received through variable or argument. Staying put."
fi


# echo "End of debugging area. Exiting."
# exit 0
# Run our install script to ensure that git is installed and configured.
 bash /scripts/git_install_setup.sh

# We've gotten this far, we know we have the required items we 
# need and can start the actual usefulness of this script.
if [ ! -d ~/.ssh ]; then
    echo ".ssh directory does not exist. creating."
    mkdir ~/.ssh
    # Force in git.ops.esu10.org into the known hosts file.
    # cat >> ~/.ssh/known_hosts <<EOF ${KNOWN_HOSTS}
    echo "$KNOWN_HOSTS" > ~/.ssh/known_hosts
fi
# Let's make sure there isn't a key present first so that we don't overwrite it.
if [ ! -e ~/.ssh/id_rsa.pub ]; then
    echo "Writing Pub Key to .ssh directory."
    echo "$DEPLOY_PUB_KEY" > ~/.ssh/id_rsa.pub
    chmod 600 ~/.ssh/id_rsa.pub
    echo "Pub key file placed. Prepping to place Private Key"
fi
if [ ! -e ~/.ssh/id_rsa ]; then
    echo "Private key file located. Yay, script can continue."
    cp $DEPLOY_PRI_KEY_LOCATION/id_rsa ~/.ssh/
fi
echo
echo "Inspecting ${WORKING_DIR}/${GIT_REPO_DIR} for a .git directory."
echo
if [ -d ${GIT_REPO_DIR}/.git ]; then
    # If the .git repo exists then this is not the first time that this script has run.
    # and our only job is to pull down any changes that might exist from the repo.
    echo "Git repo exists in ${GIT_REPO_DIR} directory"
    cd ${WORKING_DIR}/${GIT_REPO_DIR}
    BRANCH=${GIT_REPO_BRANCH:="master"}
    echo "git pull origin ${BRANCH}"
    git pull origin ${BRANCH}
else
    # There is no git directory so we assume this is the first time this script has run.
    # We need to do some initial setup.
    echo "No git directory in ${WORKING_DIR}/${GIT_REPO_DIR}. Assuming this is the first time this script has run. Commencing initialization... "
    echo 
    echo "git clone ${GIT_REPO_URL} ${WORKING_DIR}/${GIT_REPO_DIR}"
    git clone ${GIT_REPO_URL} ${WORKING_DIR}/${GIT_REPO_DIR}
    git config --global user.name "Docker Sidekick Container"
    git config --global user.email "bcone+docker_sidekick@esu10.org"

fi

# Lastly, we need to figure out how to do some additional, LS specific commands w/o always doing them...
#Do Rsync stuff to get config, pipeline, and patterns dirs in correct place
if [ ! -z "$COPY_SOME_FILES" ]; then
    echo "I was instructed to copy files based on receiving a non-empty '${COPY_SOME_FILES}' in the variable \"COPY_SOME_FILES\"."
    if [ ! -z "$COPY_SOME_FILES_DST" ]; then
        echo "As such, I am copying the contents of ${WORKING_DIR}/${GIT_REPO_DIR} to ${COPY_SOME_FILES_DST}."
        # echo "This is a logstash specific instantiation that does logstash specific things."
        mkdir -p $COPY_SOME_FILES_DST
        # ensure_directory $COPY_SOME_FILES_DST
        echo "rsync -r ${WORKING_DIR}/${GIT_REPO_DIR}/ ${COPY_SOME_FILES_DST}"
        rsync -r ${WORKING_DIR}/${GIT_REPO_DIR}/ ${COPY_SOME_FILES_DST}
    else
        echo "You instructed me to copy some files as detailed above. However, you did not tell me where you wanted"
        echo "me to place these files. Alas I cannot complete this task and your container will likely not function as"
        echo "you expect. To ensure proper operation here, be sure to set the \"COPY_SOME_FILES_DST\" variable."
    fi
fi

# Enable running a templater, in this case envplate on the files we downloaded, only if some are specified.
# We want to run it here and we expect the FINAL path of the files to be passed in.
# Otherwise they will show as changes in the git repo and prevent subsequent pulls.
if [ ! -z "$TEMPLATE_FILES" ]; then
    # Download and execute envplate to set up the variables in our config files.
    echo "A list of template files was provided. Downloading envplate to convert them."
    curl -sLo /usr/local/bin/ep https://github.com/kreuzwerker/envplate/releases/download/v0.0.8/ep-linux
    chmod +x /usr/local/bin/ep

    ep -v $TEMPLATE_FILES
fi
