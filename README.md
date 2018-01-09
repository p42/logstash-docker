# Instantiate Sidekick CI stack

This docker container doesn't do anything by itself. Rather it is intended to be a sidekick container which can pull down configuration file changes and sync them (using rsync) into place for your actual container. Developed originally to work with logstash and its config.autorestart feature but then abstracted to be more extensible.

##Configuration Variables:
At runtime, the run.sh script executes and attempts to clone/pull from a git repo. Certainly don't have to have persistent code to make this work but it does make the most sense. Variables are expected as environment variables at runtime.

###Expected Variables:                                                                       
 1. WORKING_DIR - REQUIRED - the directory in which you want the script to execute.        
 2. GIT_REPO_DIR - OPTIONAL - Directory where you want to install the repo, if you want a folder other than the repo name
 3. GIT_REPO_URL - REQUIRED - The url of the repo which you will be cloning.               
 4. GIT_REPO_BRANCH - OPTIONAL, defaults to Master Branch you want to checkout.            
 5. DEPLOY_PUB_KEY - REQUIRED, allows placement of pub key.                                
 6. DEPLOY_PRI_KEY_LOCATION - OPTIONAL - defaults to /run/secrets from Rancher config.     
 7. KNOWN_HOSTS - REQUIRED - host identity of the git repo server.                         
 8. COPY_SOME_FILES - OPTIONAL                                                             
 9. COPY_SOME_FILES_DST - REQUIRED if setting COPY_SOME_FILES. The destination path    
 10. TEMPLATE_FILES - OPTIONAL, convert environment variables in the specified, comma-delimited list of config files.
    * Make sure you also supply the environment variables necessary for these template files.