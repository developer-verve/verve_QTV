#!/bin/bash

echo "updating NME"

JEASH_DIR=/usr/lib/haxe/lib/nme/3,4,3/jeash
NME_REPO=https://raw.github.com/quicktv/NME/master/jeash

rm ${JEASH_DIR}/media/Video.hx
wget --no-check-certificate -P ${JEASH_DIR}/media ${NME_REPO}/media/Video.hx

rm ${JEASH_DIR}/net/NetStream.hx
wget --no-check-certificate -P ${JEASH_DIR}/net ${NME_REPO}/net/NetStream.hx

rm ${JEASH_DIR}/events/NetStreamEvent.hx
wget --no-check-certificate -P ${JEASH_DIR}/events ${NME_REPO}/events/NetStreamEvent.hx
