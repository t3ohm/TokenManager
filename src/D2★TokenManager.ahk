#SingleInstance, force
#include, <D2RTM>
D2RTMcore.Admin()  ; uncomment me for Admin
menu_key:="#LButton" ; I'm the Menu! comment me out or leave me blank to disable me.
D2RTM:= New D2RTM(menu_key) ; sets menu hotkey & checks for profiles in credential manager.
return