#!/bin/bash
PROXY_HOST="127.0.0.1"
NO_PROXY="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,*.local,timestamp.apple.com,sequoia.apple.com,seed-sequoia.siri.apple.com"
PROXY_PORTS=(7890 7891 7892 7893 8080 10809)

_port_found=""
for _port in "${PROXY_PORTS[@]}"; do
    if nc -z -G 1 "$PROXY_HOST" "$_port" 2>/dev/null || nc -z -w 1 "$PROXY_HOST" "$_port" 2>/dev/null; then
        _port_found="$_port"
        break
    fi
done

if [[ -n "$_port_found" ]]; then
    launchctl setenv HTTP_PROXY  "http://$PROXY_HOST:$_port_found"
    launchctl setenv HTTPS_PROXY "http://$PROXY_HOST:$_port_found"
    launchctl setenv ALL_PROXY    "socks5://$PROXY_HOST:$_port_found"
    launchctl setenv GH_PROXY     "http://$PROXY_HOST:$_port_found"
    launchctl setenv NO_PROXY     "$NO_PROXY"
else
    launchctl unsetenv HTTP_PROXY
    launchctl unsetenv HTTPS_PROXY
    launchctl unsetenv ALL_PROXY
    launchctl unsetenv GH_PROXY
    launchctl unsetenv NO_PROXY
fi
