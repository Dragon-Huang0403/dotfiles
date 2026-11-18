# bk completion
_bootstrap_bk () {
    if [ -f /usr/local/bin/bk ]; then
        source <(bk completion zsh)
        _bk
    fi
}
compdef _bootstrap_bk bk

# Prompt (aka PS1)
PROMPT="%B%F{014}%n%f%b %F{015}in%f %B%F{011}%2~%f%b \$vcs_info_msg_0_ $ "

# Java 21
if [ -d /Library/Java/JavaVirtualMachines/zulu-21.jdk ]; then
    export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home"
    export PATH="$JAVA_HOME/bin:$PATH"
elif [ -d /opt/homebrew/opt/openjdk@21 ]; then
    export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
    export JAVA_HOME=$(/usr/libexec/java_home -v 21)
fi

#
# Java
#

# Homebrew's `mvn` wrapper defaults JAVA_HOME to /opt/homebrew/opt/openjdk
# (currently JDK 26) when unset, which silently disables Lombok annotation
# processing. Pin to the nix-provided Zulu JDK 21 instead.
_java_bin=/run/current-system/sw/bin/java
if [[ -x $_java_bin ]]; then
  export JAVA_HOME=${_java_bin:A:h:h}
fi
unset _java_bin

init_bk_dqs_tokens() {
  export AUTH_X_SERVER_URL="https://authxserver.dqs.booking.com"
  export BK_AUTH_SSO_URL="https://account.dev.booking.com/SSO/staff/auth?redirect_to=https://bk-authentication-sso.dqs.booking.com/v1/redirect?redirect_to=http://localhost:8980"
  export BK_REFRESH_TOKEN="$(bk auth:issue-sso-refresh-token)"
  export IAM_TOKEN="$(bk auth:issue-sso-access-token)"
  echo "AUTH_X_SERVER_URL=$AUTH_X_SERVER_URL"
  echo "BK_AUTH_SSO_URL=$BK_AUTH_SSO_URL"
  echo "BK_REFRESH_TOKEN=$BK_REFRESH_TOKEN"
  echo "IAM_TOKEN=$IAM_TOKEN"
}
init_bk_tokens() {
  export AUTH_X_SERVER_URL="https://authxserver.booking.com"
  export BK_AUTH_SSO_URL="https://account.dev.booking.com/SSO/staff/auth?redirect_to=https://bk-authentication-sso.dqs.booking.com/v1/redirect?redirect_to=http://localhost:8980"
  export BK_REFRESH_TOKEN="$(bk auth:issue-sso-refresh-token)"
  export IAM_TOKEN="$(bk auth:issue-sso-access-token)"
  echo "AUTH_X_SERVER_URL=$AUTH_X_SERVER_URL"
  echo "BK_AUTH_SSO_URL=$BK_AUTH_SSO_URL"
  echo "BK_REFRESH_TOKEN=$BK_REFRESH_TOKEN"
  echo "IAM_TOKEN=$IAM_TOKEN"
}

get_fqdn(){
    export FQDN="$(kubectl describe svc | grep kubernetes.fqdn | tr -d ' ' | cut -d: -f2 | head -n1)"
    echo "FQDN=$FQDN"
}

export KVM_HOST="lohuang-cron.dev.booking.com"
DB_CREDENTIAL_CACHE=""
get_db_credential_from_kvm() {
    if [ -z "$DB_CREDENTIAL_CACHE" ]; then
        DB_CREDENTIAL_CACHE="$(ssh $KVM_HOST 'cat /var/run/secrets/booking.com/db.json')"
    fi
    echo $DB_CREDENTIAL_CACHE
}

select_db_credential_from_kvm(){
    json="$(get_db_credential_from_kvm)"
    db=$(jq -r '.database | keys[]' <<<"$json" | fzf)
    jq --arg db "$db" '.database[$db]' <<<"$json"
}

connect_dqs_db(){
    local credentials
    credentials="$(select_db_credential_from_kvm)" || return
    jq -e '.rw | .driver == "mysql" and (.host | length > 0) and (.username | length > 0) and (.database | length > 0) and (.password | type == "string")' <<< "$credentials" >/dev/null || {
        print -u2 'Missing or invalid rw MySQL credentials'
        return 1
    }
    DATABASE="$(jq -r '.rw.database' <<< "$credentials")"
    HOST="$(jq -r '.rw.host' <<< "$credentials")"
    USER="$(jq -r '.rw.username' <<< "$credentials")"
    echo ">> Connecting to $DATABASE on $HOST as $USER"
    echo ">> To list all databases: SHOW DATABASES;"
    echo ">> To list tables in the selected database: SHOW TABLES;"
    echo "\n============================================================\n"
    mycli \
        --host "$HOST" \
        --port "$(jq -r '.rw.port // 3306' <<< "$credentials")" \
        --user "$USER" \
        --database "$DATABASE" \
        --password-file <(jq -jr '.rw.password' <<< "$credentials") \
        --use-keyring false
}

kvm() {
    ssh $KVM_HOST
}

bl(){
    bk auth:login && glab auth login --hostname gitlab.com # && acli auth login
}
