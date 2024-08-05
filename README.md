### ansible-vault-env

automaticly load your project secrets and env-files to environment

### installation
- install `ansible`
- install plugin `fisher install pat-xd/ansible-vault-env.fish`

### usage
- automaticly load your vault and env file to the environment, if these files are in your current directory
- create a new vault with `vault create`
    - this create a random secret safe it to your vault-key file and create an ansible-vault
- use the functions `vault view/edit/load` so that the unencrypted file is not accidentally pushed into a repository
- store your public project variables in to an .env file and also load it automaticly


### customization
- set -g VAULT_PASSKEY_FILE_NAME .vault-key
- set -g VAULT_FILE_NAME .vault
- set -g CREATE_RANDOM_DEFAULT 24
- set -g ENV_FILE .env
