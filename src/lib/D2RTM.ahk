#include, <D2RTMcore>
class D2RTM extends D2RTMcore {
    static defaulttitle:="Diablo II: Resurrected"
    static NameFrame := "D2R:"
    static winHeight := 1300
    static winWidth := 768
    static X:=(A_ScreenWidth/2)-(1300/2)
    static Y:=(A_ScreenHeight/2)-(768/2)
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
        return this.Token.ToBin(SelectedProfile)
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
            WinWait, % this.bnet.D2R.defaulttitle
            this.Hwnd.Move(this.Hwnd.Get(this.bnet.D2R.defaulttitle))
            this.UpdatedToken(this.bnet.D2R.defaulttitle,SelectedProfile)
            ;this.CollectToken()
            this.savetoken(SelectedProfile)
            this.bnet.D2R.kill()
            return 1
        
    }
    CollectToken(){ ;
        tokens:={}
        maxtokens=4
        last4:=SubStr(token:=this.Get(), -4)
        tokens.push(lastlast4:=last4)
        loop,
        {   
            if (last4 != lastlast4){
                tokens.push(lastlast4:=last4)
                
            }
            collected:=tokens.MaxIndex()
            if (collected = maxtokens){
                return 1
            }
            if ((mod(cycle, 3) = 0)){
                this.window.Spacer(this.defaulttitle)
            }
            cycle++
            last4:=SubStr(token:=this.Get(), -4)
            
        }
    } 
    UpdatedToken(title,SelectedProfile){
        this.Hwnd.Move(title)
        while (!this.bnet.D2R.online() and !this.bnet.D2R.Onlinegamecreation())
        {   
            this.isMove()
            this.window.Spacer(title)
            sleep, 1000
        }
        cycle:=0
        return this.savetoken(SelectedProfile)
    }
    isToken(profilename){
        if (FileExist(this.Token.File(profilename))){
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
    StartOffline(){
        this.Token.Clear()
        if PID:=this.bnet.D2R.Start()
            WinWait, % this.defaulttitle
        while (!this.Sentinal()){
        }

    }
    StartToken(SelectedProfile=""){
        if !SelectedProfile
            SelectedProfile:=this.profile.input()
        if !SelectedProfile
            return 0
        this.loadtoken(SelectedProfile)
        if PID:=this.bnet.D2R.Start()
            WinWait, % this.defaulttitle
        this.Hwnd.Move(this.defaulttitle)
        starttitle:=this.bnet.D2R.title(SelectedProfile)
        sleep, 3000
        result:=this.UpdatedToken(starttitle,SelectedProfile)
        while (!this.Sentinal()){
        }
            WinMinimize, % starttitle
            WinMinimize,
        return result
    }
    CSR(SelectedProfile=""){ ;Close handle,Save token, Rename window
        this.Sentinal()
        this.savetoken(SelectedProfile)
        this.Rename(SelectedProfile)
    }
    Rename(SelectedProfile){
        newtitle:=this.NameFrame SelectedProfile
        if (D2RTMcore.Window.title(this.defaulttitle,newtitle)){
            return newtitle
        }
    }
    RefreshAll(){
        for profile,name in this.profile.Update()
            {
                if (this.Refreshtoken(name)){
                    rcount++
                }
            }
        return rcount
    }
    StartAll(){
        for profile,name in this.profile.Update()
            {
                this.Token.Clear()
                if (this.StartToken(name)){
                    this.window.min("D2R:" name,1)
                    scount++
                }
            }
        return scount
    }
    menuDestroy(){
        Menu, D2RTM, DeleteAll
    }
    Menu(){
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
                    if (A_index = 1){
                        Menu, Launchers, Add, All, StartAll
                    }
                    menu, Launchers, add, % name, menu_launcher
                    Menu, CSRs, Add, % name, CSR
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
            menu, D2RTM, add, Start, :Launchers
        }
        if (ProfileCount){
            menu, Profile, add, CSR, :CSRs
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
    isMove(){
        WinGetPos, X, Y, Width, Height, % D2RTM.defaulttitle
        if (X != D2RTM.X){
            D2RTM.window.Move(D2RTM.defaulttitle,D2RTM.X,D2RTM.Y)
            return 1
        }
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
    getout:
        Exitapp
    return
    CSR:
        D2RTM.CSR(A_ThisMenuItem)
    return 
}
