#!/bin/sh
# tshock startup script

set -e

#copy plugins over i
[ "$(ls -A /plugins)" ] && cp -f /plugins/* /tshock/ServerPlugins

exec mono --server --gc=sgen -O=all TerrariaServer.exe -configpath /config -worldpath /world -logpath /logs "$@"
