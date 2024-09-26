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
               if echo $line | grep -qE '[a-zA-Z_0-9]+([:=])[ \'\"]*[a-zA-Z_0-9]+[ \'\"]*$'
                   set deli $(echo $line | grep -Eo '[a-zA-Z_0-9]+([:=])[ \'\"]*[a-zA-Z_0-9]+[ \'\"]*$' | grep -Eo '[:=]')
                   set key (echo $line | grep -oE '[a-zA-Z_0-9]+([:=])[ \'\"]*[a-zA-Z_0-9]+[ \'\"]*$' | cut -d "$deli" -f 1)
                   set value (echo $line | cut -d "$deli" -f 2 | sed 's/"//g' | sed s#\'##g)
                   set -xg $key "$value"
               end
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
    if test -f $ENV_FILE
        for line in (cat $ENV_FILE)
           # Skip empty lines
           if test -z "$line" -o (string sub -s 1 -l 1 $line) = "#"
               continue
           end
           if echo $line | grep -qE '[a-zA-Z_0-9]+([:=])[ \'\"]?[a-zA-Z_0-9]+[ \'\"]?$'
               set deli $(echo $line | grep -Eo '[a-zA-Z_0-9]+([:=])[ \'\"]?[a-zA-Z_0-9]+[ \'\"]?$' | grep -Eo '[:=]')
               set key (echo $line | grep -oE '[a-zA-Z_0-9]+([:=])[ \'\"]?[a-zA-Z_0-9]+[ \'\"]?$' | cut -d "$deli" -f 1)
               set value (echo $line | cut -d "$deli" -f 2 | sed 's/"//g' | sed s#\'##g)
               set -xg $key "$value"
           end
        end
    end
end
