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

init_bk_tokens() {
  export AUTH_X_SERVER_URL="https://authxserver.dqs.booking.com"
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

