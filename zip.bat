@echo off
if not exist build mkdir build
powershell -command "Compress-Archive -Update -Path 'main.lua', 'conf.lua', 'lib', 'src', 'data' -DestinationPath 'build/interconnect.zip'"
move /Y build\interconnect.zip build\interconnect.love