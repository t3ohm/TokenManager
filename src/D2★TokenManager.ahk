#include, <D2RTMcore>
;D2RTMcore.Admin()  
/*
    I'm the Menu! you can set the default key here.
    The default is already Winkey+Leftmouse by default.
    You cab delete menu_key line on line 8.. 
    Or uncomment it and change it. 
    */
;menu_key:="#LButton" 
    /*
    sets hotkey for menu and checks 
    for any profiles already in credential manager
    */
D2RTM:= New D2RTMcore.D2RTM(menu_key)
