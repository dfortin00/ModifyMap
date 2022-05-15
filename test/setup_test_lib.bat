rmdir /Q /S lib\mapmatic
rmdir /Q /S lib\mapmatic

xcopy ..\..\..\MapMatic\mapmatic  lib\mapmatic /E/H/C/I
xcopy ..\ModifyMap  lib\mapmatic\plugins\ModifyMap /E/H/C/I