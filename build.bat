@echo off

cd src
pdc -sdkpath "path to your sdk" -m main.lua ../build/notfnf.pdx
cd ..