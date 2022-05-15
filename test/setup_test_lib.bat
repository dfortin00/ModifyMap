rmdir /Q /S lib\mapmatic
rmdir /Q /S lib\mapmatic

rem Modify source directory to the location of the MapMatic library before executing.
xcopy ..\..\..\MapMatic\mapmatic  lib\mapmatic /E/H/C/I

rem Copies the ModifyMap folder into the mapmatic/plugins folder for testing purposes.
xcopy ..\ModifyMap  lib\mapmatic\plugins\ModifyMap /E/H/C/I