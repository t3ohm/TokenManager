#include, <D2RTMcore>
class D2RTM extends D2RTMcore {
    __New(menukey=""){
        D2RTMcore.New()
        D2RTMcore := New D2RTMcore
        D2RMENU:= ObjBindMethod(this,"Show")
        if (menukey != "") {
        Hotkey, %menukey%, % D2RMENU, on
        this.Menu()
        } 
        
    }
    savetoken(SelectedProfile=""){
        if !SelectedProfile
            SelectedProfile:=this.profile.input()
        return this.token.ToBin(SelectedProfile)
    }
    loadtoken(SelectedProfile){
        return this.Token.Load(this.Token.FromBin(SelectedProfile))
    }
    Refreshtoken(SelectedProfile=""){
        if !SelectedProfile
            SelectedProfile:=this.profile.input()
            this.bnet.KillAll()
            this.bnet.startBnet()
            sleep, 2250
            this.bnet.movelogin()
            sleep, 2250
            this.bnet.startBnet()
            SetKeyDelay, 10
            sleep, 3000
            this.bnet.login(this.profile.retrieve(SelectedProfile).usr,this.profile.retrieve(SelectedProfile).passwd,tabup:=1)
            while (1)
            {
                if (this.bnet.verify()){
                    if (this.bnet.verifywayup()){
                        while (!this.bnet.cats())
                        {
                            sleep, 1000
                        }
                        while (!this.bnet.verified())
                        {
                            sleep, 1000
                        }
                        while (!this.bnet.verifylogin())
                        {
                            sleep, 1000
                        }
                    }
                }
                if this.bnet.D2R.Select()
                    break
            }
            ;didn't click play 1/3
            WinWait, % this.bnet.D2R.defaulttitle
            this.Hwnd.Move(this.Hwnd.Get(this.bnet.D2R.defaulttitle))
            this.UpdatedToken(this.bnet.D2R.defaulttitle,SelectedProfile)
            this.bnet.D2R.kill()
            return 1
        
    }
    UpdatedToken(title,SelectedProfile){
        while (!this.bnet.D2R.online() and !this.bnet.D2R.Onlinegamecreation())
        {   
            if ((mod(cycle, 2) = 0)){
                this.Hwnd.Spacer(this.Hwnd.Get(title))
            }
            cycle++
            sleep, 1000
        }
        cycle:=0
        return this.savetoken(SelectedProfile)
    }
    isToken(profilename){
        if (FileExist(tokenfile:=this.Token.File(profilename))){
            return 1
        }
        
    }
    Sentinal(){
        if (this.handle.close()){
            this.log(A_ThisFunc ":" Mutex killed)
            return 1
        } else {
            this.log(A_ThisFunc ":" no Mutex)
            return 0
        }
    }
    StartToken(SelectedProfile=""){
        ;MsgBox, %SelectedProfile%
        
        if !SelectedProfile
            SelectedProfile:=this.profile.input()
        if !SelectedProfile
            return 0
        this.loadtoken(SelectedProfile)
        if PID:=this.bnet.D2R.Start()
            WinWait, Diablo II: Resurrected
        sleep, 50
        starttitle:=this.bnet.D2R.title(SelectedProfile)
        sleep, 50
        this.Hwnd.Move(gamehwnd:=this.Hwnd.Get(starttitle))
        sleep, 3000
        result:=this.UpdatedToken(starttitle,SelectedProfile)
        while (!this.Sentinal()){
            WinMinimize, % "ahk_id" gamehwnd
        }
        return result
    }
    RefreshAll(){
        for profile,name in this.profile.Update()
            {
                MsgBox,,, % name, % (1/3)
                if (this.Refreshtoken(name)){
                    rcount++
                }
            }
        return rcount
    }
    StartAll(){
        for profile,name in this.profile.Update()
            {
                MsgBox,,, % name, % (1/3)
                this.Token.Clear()
                if (this.StartToken(name)){
                    scount++
                }
            }
        return scount
    }
    menuDestroy(){
        Menu, D2RTM, DeleteAll
    }
    Menu(){
        menu, D2RTM, add
        Menu, settings, Add, Reload, restart
        menu, settings, Add, Exit, getout
        
        Menu, D2RTM, Add, D2R:TokenManager, :settings
        Menu, D2RTM, add,,,+BarBreak
        ;add userprofiles if exist
        Allprofiles:=this.profile.Update()
        if (ProfileCount:=Allprofiles.MaxIndex()){
            ;menu, Launch, add,,nothing, +barbreak
            ;menu, Refresh, add,,nothing, +barbreak
            Menu, Tokens, add, Save token, savetoken
            Menu, Refreshers, Add, All, RefreshAll
            for profile,name in Allprofiles
            {
                menu_profile:=Allprofiles[A_Index]
                if (this.isToken(menu_profile)){
                    menu, Launchers, add, % name, menu_launcher
                } else {
                    disabledname:="No Token, Refresh " name
                    menu, Launchers, add, % disabledname, menu_launcher
                    menu, Launchers, Disable, % disabledname
                }
                menu, Refreshers, add, % name, menu_refresher
                Menu, Tokens, Add, % name, menu_ProfileTokenSave
            }
            ;menu, Start, add, Start, :Launchers
            ;menu, Refresh, add, Refresh, :Refreshers
            
            ;Menu, Start, Add, Token, starttoken
            ;Menu, Start, Add, All, StartAll
            menu, D2RTM, add, Start, :Launchers
        }
        if (ProfileCount){
            Menu, Profile, Add, Token, :Tokens
            Menu, Profile, Add, List, List
            menu, D2RTM, add, Refresh, :Refreshers
            ;Menu, Refresh, Add, Token, Refreshtoken
            
        }
        ;Menu, Profile, Add, Token
        Menu, Profile, Add, Add, AddProfile
        Menu, Profile, Add, Delete, DeleteProfile
        menu, D2RTM, add, Profile, :Profile
        menu, Tray, Add, D2RTM, :D2RTM
    }
    Show(){
        this.menuDestroy()
        this.Menu()
        Menu, D2RTM, Show
    }

} ;end of D2RTM

if false { ;class labels for menus
    list:
        msgbox, % D2RTM.profile.List()
    return
    starttoken:
        D2RTM.StartToken(A_ThisMenuItem)
    return
    StartAll:
        D2RTM.StartAll()
    return
    Refreshtoken:
        D2RTM.Refreshtoken()
    return
    RefreshAll:
        D2RTM.RefreshAll()
    return
    savetoken:
        D2RTM.savetoken()
    return
    menu_ProfileTokenSave:
         D2RTM.savetoken(A_ThisMenuItem)
    return
    AddProfile:
         D2RTM.profile.Create()
    Return
    DeleteProfile:
        D2RTM.profile.Remove()
    return
    restart:
        Reload
    return
    menu_launcher:
        D2RTM.StartToken(A_ThisMenuItem)
    return
    menu_refresher:
         D2RTM.Refreshtoken(A_ThisMenuItem)
    return
    detroy_menu:
       
    return
    nothingtodo:
    return
    getout:
        Exitapp
    return
}