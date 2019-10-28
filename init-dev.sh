#!/bin/bash
if [ ! -d ./Libs ]; then
    mkdir ./Libs
fi
if [ ! -d ./Libs/HereBeDragons ]; then
    git clone https://repos.wowace.com/wow/herebedragons ./Libs/HereBeDragons
fi
if [ ! -d ./Libs/LibStub ]; then
    svn checkout https://repos.wowace.com/wow/libstub/trunk ./Libs/LibStub
fi
