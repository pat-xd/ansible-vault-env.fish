if set not -q CREATE_RANDOM_DEFAULT
    set -g CREATE_RANDOM_DEFAULT 24
end
if set not -q VAULT_FILE_NAME
    set -g VAULT_FILE_NAME .vault
end
if set not -q VAULT_PASSKEY_FILE_NAME
    set -g VAULT_PASSKEY_FILE_NAME .vault-key
end
if set not -q ENV_FILE
    set -g ENV_FILE .env
end

function auto_activate_vault --on-variable PWD -d "auto-activate env from ansible-vault"
    if test -f $VAULT_FILE_NAME -a -f $VAULT_PASSKEY_FILE_NAME
        for line in (ansible-vault view --vault-password-file $VAULT_PASSKEY_FILE_NAME $VAULT_FILE_NAME | string split '\n')
               # Skip empty lines
               if test -z "$line" -o (string sub -s 1 -l 1 $line) = "#"
                   continue
               end

               # Split the line into key and value
               set -l key (echo $line | cut -d':' -f1)
               set -l value (echo $line | cut -d':' -f2-)

               # Set the environment variable
               set -xg $key $value
           end
    end
end

function create_random -d"create a random string"
    set -l len $CREATE_RANDOM_DEFAULT
    if count $argv > 0
        set len $argv[1]
    end
    set random_string (openssl rand -base64 $len | tr -dc 'a-zA-Z0-9' | head -c $len)
           echo $random_string
end

function vault -d "create, view, load or edit an ansible-vault"
    switch $argv[1]
        case "create"
            if test -f $VAULT_FILE_NAME
                echo "$VAULT_FILE_NAME exist; remove it first"
                exit 1
            end
            echo "create ansible-vault"
            set secret (create_random)
            echo $secret > $VAULT_PASSKEY_FILE_NAME
            ansible-vault create --vault-password-file $VAULT_PASSKEY_FILE_NAME $VAULT_FILE_NAME
        case "view"
            ansible-vault view --vault-password-file $VAULT_PASSKEY_FILE_NAME $VAULT_FILE_NAME
        case "edit"
            ansible-vault edit --vault-password-file $VAULT_PASSKEY_FILE_NAME $VAULT_FILE_NAME
        case "load"
            auto_activate_vault
    end

end

function auto_activate_env --on-variable PWD -d "auto-activate env if exists on change-directory"
    if test -f .env
        source .env
    end
end
