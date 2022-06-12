ListLines, off
#include <FindText>
;#Include, <ADMIN>
#SingleInstance, force
ListLines, on
class D2RTMcore {
    ;functions
    static configdir:="\config"
    static bindir:= "\bin"
    static libsdir:= "\libs"
        __New(){
            configDIR:=A_ScriptDir this.configdir
            if (!FileExist(configDIR)){
				FileCreateDir, % configDIR
			}
            binDIR:=configDIR this.bindir
            if (!FileExist(binDIR)){
				FileCreateDir, % binDIR
			}
            libsdir:=configDIR this.libsdir
            if (!FileExist(libsdir)){
				FileCreateDir, % libsdir
			}
            if (!FileExist(handleDir:=libsdir "\handle")){
                FileCreateDir, % handleDir
			}
            
            if (!FileExist(handleDir "\handle" this.cmd.GetArch() ".exe")){
                archive:=handleDir "\Handle.zip"
                UrlDownloadToFile, https://download.sysinternals.com/files/Handle.zip , % archive
                this.zip.unpack(archive,handleDir)

                MsgBox, waiting
                FileDelete, % archive
        
            }
              



        }
        Admin(){
            if not A_IsAdmin {
                run *RunAs "%A_ScriptFullPath%"
                ExitApp
            }
        }
        tip(ptext,ptime=75){
                messagetimeout:=(ptime)
                loop, 12
                {
                ToolTip, % A_Scriptname ":" ptext this.tick(3), 0, 0, 1
                sleep, % messagetimeout
                }
                ToolTip,,,,1
        }
        tick(tock=1){
                static ticktock
                if (StrLen(ticktock) = tock ){
                    return ticktock:=""
                } else  {
                    return ticktock.="."
                }
        }
        timestamp(){
                FormatTime, vTime, , yyyyMMddHHmmss
                return vTime
        }
        
    class process {
        PIDbyExe(exe){
            process, exist, % exe
            return ErrorLevel
        }
        closeExe(exe){
            process, close, % exe
            return ErrorLevel
        }
    }
    class window {
        title(old,new){
            WinSetTitle, % old,, % new
            return ErrorLevel
        }
    }
    class cmd {
        stdOut(command){
            ;msgbox, % command
            ;stdout := runStdout(command)
            return this.hideout(command)

        }
        showout(command) {
            shell := comobjcreate("WScript.shell")
            exec := (shell.exec(comspec " /c " command))
            stdout := exec.stdout.readall()   
            Return stdout
        }
        hideout(Target="null.exe", Size:=""){
            ;MsgBox, % Target
            DetectHiddenWindows, On
            pComSpec := A_ComSpec ? A_ComSpec : ComSpec
            Run, % pComSpec,, Hide, pid
            WinWait, % "ahk_pid " pid
            DllCall("kernel32\AttachConsole", "UInt",pid)00
            shell := ComObjCreate("WScript.Shell")
            Exec := shell.Exec(Target)
            StdOut := ""
            if !(Size = "")
                VarSetCapacity(StdOut, Size)
            while !Exec.StdOut.AtEndOfStream
                StdOut := Exec.StdOut.ReadAll()
            DllCall("kernel32\FreeConsole")
            Process, Close, % pid
            return StdOut
        }
        GetArch(){
            for sysinfo in ComObjGet("winmgmts:\\.\root\cimv2").ExecQuery("SELECT OSArchitecture FROM Win32_OperatingSystem")
                return sysinfo.OSArchitecture="64-bit"?"64":""
        }
    } 
    class zip {
            unpack(sZip, sUnz){
                fso := ComObjCreate("Scripting.FileSystemObject")
                If Not fso.FolderExists(sUnz)  ;http://www.autohotkey.com/forum/viewtopic.php?p=402574
                fso.CreateFolder(sUnz)
                psh  := ComObjCreate("Shell.Application")
                zippedItems := psh.Namespace( sZip ).items().count
                psh.Namespace( sUnz ).CopyHere( psh.Namespace( sZip ).items, 4|16 )
                Loop {
                    IfEqual,zippedItems,%unzippedItems%
                        break
                }
            }
    }
    class registry {
        read(fullkey,valuename){
            ;msgbox, % A_LineNumber
            RegRead, token, % fullkey , % valuename
            if !ErrorLevel
                return token
            else
                return ""
        }
        write(fullkey,valuename,value){
            ;msgbox, % A_ThisFunc "`n" fullkey "`n" valuename "`n" value
            RegWrite, REG_BINARY, % fullkey, % valuename, % value
			return !ErrorLevel
        }
        delete(fullkey,valuename){
            RegDelete, % fullkey , % valuename
            return !ErrorLevel
        }
    } 
    class Token extends D2RTMcore.registry {
        static key:="HKEY_CURRENT_USER"
        static subkey:="SOFTWARE\Blizzard Entertainment\Battle.net\Launch Options\OSI"
        static fullkey:="HKEY_CURRENT_USER\SOFTWARE\Blizzard Entertainment\Battle.net\Launch Options\OSI"
        static valuename:="WEB_TOKEN"
        static binpath:="config\bin\"
        static binext:=".bin"
        Check(token){
			if ( token = this.Read())
				return 1
		}
		Get(){
			return this.read(this.fullkey,this.valuename)
		}
		File(name,binpath=""){
            if (binpath = ""){
                binpath := this.binpath
    			return binpath name this.binext
            }
		}
		ToBin(profilename,token=""){
            if (token = "")
                token:=this.Get()
			tokenfile:=this.File(profilename)
            ;msgbox, % tokenfile
			if (FileExist(tokenfile))
				FileDelete, % tokenfile
			FileAppend, % token, % tokenfile
			return !ErrorLevel
		}
		FromBin(profilename){
			tokenfile:=this.File(profilename)
			if !FileExist(tokenfile)
				MsgBox, % profilename " token file not found`n" tokenfile
			FileRead, token, % tokenfile
			if token {
				return token
				} else {
				return 0
				}
		}
        Clear(){
			;RegDelete, % this.fullkey , % this.valuename
            return D2RTMcore.registry.delete(this.fullkey,this.valuename)
		}
		Load(token){
			return D2RTMcore.registry.write(this.fullkey,this.valuename,token)
		}
        
    } 
    class handle extends D2RTMcore.cmd {
        close(name="D2R.exe"){
            pid := 0
            handle := this.get(pid,name)
            if (handle.handle = "") {
                msgbox, % A_LineNumber
                return 0 ; handle not found
            }
            commandexe:=A_ScriptDir . "\config\libs\handle\handle" this.GetArch() ".exe"
            command := commandexe " -nobanner -p " . handle.pid . " -c " . handle.handle . " -y"
            this.stdOut(command)
            ;Run, %comspec% /c %command%,, Hide
            return 1
        }    
        get(ByRef pid,name) {
            ;msgbox, % commandexe:=A_ScriptDir . "config\libs\handle\handle" this.GetArch() ".exe"
            command := A_ScriptDir . "\config\libs\handle\handle" this.GetArch() ".exe -nobanner -a -p " . name . " Instances"
            stdout := this.stdOut(command)
            needle := "No matching" ;when Handle found nothing return in standard output "No matching handles found."
            IfInString, stdout, %needle%
                {
                msgbox, % A_LineNumber
                return ""
                }	
            handle := RegExReplace(stdout, "s).*(...): \\Sessions\\\d*\\BaseNamedObjects\\DiabloII.*", "$1")
            pid := RegExReplace(stdout, "s).*pid: (\d*)\s*.*", "$1")
            ;MsgBox,,, % stdout . "`nhandle:" . handle . "`npid:" . pid
            info:= {"handle": handle, "pid": pid}
            Return info
        }
    } 
    class cmdkey extends D2RTMcore.cmd {
        List(target=""){
            command:="cmdkey /List:" target
            return this.stdOut(command)
        }
        AddGeneric(targetName,Username,Password){
            ;MsgBox, % targetName "`n" Username "`n" Password
            if (targetName=""){
                InputBox, targetName, % A_ThisFunc, Enter Target Name,, %Width%, %Height%, %X%, %Y%
            }
            if (Username=""){
                InputBox, Username,  % A_ThisFunc, Enter Username,, %Width%, %Height%, %X%, %Y%
            }
            if (Password=""){
                InputBox, Password,, % "Enter Password for " Username, HIDE, %Width%, %Height%, %X%, %Y%
            }
            command:="cmdkey /generic:" targetName " /user:" Username " /pass:" Password
            result:=this.stdOut(command)
            ;MsgBox, % result
            if this.stdOut(command) ~=successfully
                return result
            else
                return 0
            
        }
        Delete(targetName){
            if (targetName=""){
                InputBox, targetName, % A_ThisFunc, Enter Target Name To Delete,, %Width%, %Height%, %X%, %Y%
            }
            if this.stdOut("cmdkey /Delete:" targetName) ~=successfully
                return 1
            else
                return 0
        }
        Get(targetName) {
            local pCred := 0
            local ret := DllCall( "ADVAPI32\CredReadW", "WStr", targetName, "UInt", 1, "UInt", 0, "Ptr*", pCred, "Int" )
            if ( 0 != ErrorLevel ) {
                MsgBox % A_LineNumber "`nDllCall error invoking CredReadW: " . ErrorLevel
                return
            }
            if ( 1 != ret ) {
                MsgBox % A_LineNumber "`nError from CredRead: " . A_LastError
               return
            }
            local credentialBlobSizeOffset := 16 + 2*A_PtrSize
            local uCredentialBlobOffset	:= 24 + 6*A_PtrSize
            local pCredentialBlobOffset	:= 16 + 3*A_PtrSize

            local credentialBlobSize := NumGet( pCred + credentialBlobSizeOffset, "UInt" )
            local uCredentialBlob	:= NumGet( pCred + uCredentialBlobOffset,	"Ptr" )
            local pCredentialBlob	:= NumGet( pCred + pCredentialBlobOffset,	"Ptr" )


            username := StrGet( uCredentialBlob,, "UTF-16" )
            password := StrGet( pCredentialBlob, credentialBlobSize / 2, "UTF-16" )

            DllCall( "ADVAPI32\CredFree", "Ptr", pCred )
            if ( 0 != ErrorLevel ) {
                MsgBox % A_LineNumber "`nDllCall error invoking CredFree: " . ErrorLevel
                return
            }

            
            ;MsgBox, %targetName% A_LineNumber
            return {"usr": username, "passwd": password}
        }
    } 
    class profile extends D2RTMcore.cmdkey {
        
        Update(byref pProfiles=""){
            AllProfiles:={}
            ;msgbox % keys:=D2RTMcore.cmdkey.List()
            tosort:=
            ListLines, off
            loop, parse, % keys:=D2RTMcore.cmdkey.List(), `n,`r
            {
                uprofile:=
                RegExMatch(A_LoopField, "D2RTM[A-Za-z0-9-_]*" , uprofile)
                ;MsgBox, % uprofile
                if uprofile {
                    uprofile:=RegExReplace(uprofile, "D2RTM[_][_](.*)$" , "$1")
                    tosort.=uprofile "`n"
                    ;MsgBox, % A_thisfunc "`n" uprofile
                }
            }
            Sort, tosort
            loop, parse, % tosort, `n`r
            {
                if (A_LoopField){
                    AllProfiles.push(A_LoopField)
                }
            }
            ListLines, on
            if (pProfiles){
                return pProfiles:=AllProfiles
            } else {
                return AllProfiles
            }
        }
        Remove(target=""){
            if !target
                target:=this.input()
            if !target
                return 0
            pT:="D2RTM__" target
            return D2RTMcore.cmdkey.Delete(pT)
        }
        Add(target,UN,PW){
            D2RTMcore.cmdkey.AddGeneric(this.nameframe(target),UN,PW)
            pT:="D2RTM__" target
            D2RTMcore.cmdkey.AddGeneric(pT,UN,PW)
        }
        List(){
            ;global AllProfiles
            profiles:=this.Update()
            info:="Available Profiles: " count:=profiles.MaxIndex()
            loop, % count
                {
                info.="`n[" A_index "]" profiles[A_index]
                }
                return info
        }
        next(allprofiles){

            static nextprofile
            maxprofiles:=allprofiles.MaxIndex()
            nextprofile+=1
            ;MsgBox, %nextprofile%
                if ( nextprofile < maxprofiles ){
                    return allprofiles[nextprofile]
                } else  {
                    return allprofiles[((nextprofile:=0)+maxprofiles)]
                }
        }
        Create(){
            Gui CREATEPROFILEGUI:Destroy
            global vCREATEPROFILE_PROFILENAME
            global vCREATEPROFILE_USERNAME
            global vCREATEPROFILE_PASSWORD
            global OKHolder
            global CancelHolder
            Gui CREATEPROFILEGUI:-MinimizeBox -MaximizeBox +AlwaysOnTop -Theme +Owner
            Gui CREATEPROFILEGUI:Font, s20 q5 c0x00FF00, ExocetBlizzardMixedCapsOTMedium
            Gui CREATEPROFILEGUI:Color, 0x808080
            Gui CREATEPROFILEGUI:Add, GroupBox, x8 y8 w307 h70, Profile Name
            Gui CREATEPROFILEGUI:Add, Edit, x16 y32 w290 h39 vvCREATEPROFILE_PROFILENAME, Name
            Gui CREATEPROFILEGUI:Add, GroupBox, x8 y72 w307 h70, Login/Username
            Gui CREATEPROFILEGUI:Add, Edit, x16 y96 w290 h39 vvCREATEPROFILE_USERNAME, username
            Gui CREATEPROFILEGUI:Add, GroupBox, x8 y136 w307 h70, Password
            Gui CREATEPROFILEGUI:Add, Edit, x16 y160 w290 h39 vvCREATEPROFILE_PASSWORD +Password, password
            {Gui CREATEPROFILEGUI:Add, Button, x176 y208 w122 h57 HwndCancelHolder, Cancel
                DeleteProfile := ObjBindMethod(this, "CreateCANCEL")
                    GuiControl +g, %CancelHolder%, % DeleteProfile
                }
            {Gui CREATEPROFILEGUI:Add, Button, x24 y208 w122 h57 HwndOKHolder, Create
                CreateProfile := ObjBindMethod(this, "CreateSUBMIT")
                    GuiControl +g, %OKHolder%, % CreateProfile
                }

            Gui CREATEPROFILEGUI:Show, w322 h271, Create Profile
        }
        CreateSUBMIT(){
            global pin
            global vCREATEPROFILE_PROFILENAME
            global vCREATEPROFILE_USERNAME
            global vCREATEPROFILE_PASSWORD
            gui, CREATEPROFILEGUI:Submit
            this.add(vCREATEPROFILE_PROFILENAME,vCREATEPROFILE_USERNAME,vCREATEPROFILE_PASSWORD)
            Gui CREATEPROFILEGUI:Destroy
        }
        CreateCANCEL(){
            Gui CREATEPROFILEGUI:Destroy
        }
        ByNameOrPos(name=""){
            if !name {
                name:=this.input()
            }
            ; check first for username
			for i,o in allprofiles:=this.Update() 
			{   
				if (allprofiles[i] = name ){
                    MsgBox, %o%
					return o
				} 
			}
            ; else check by position
            for i,o in allprofiles 
			{   
				if (i = name ){
                    MsgBox, %o%
                    return allprofiles[i]
				} 
			}
		}
        namebypos(position){
            for i,o in allprofiles:=this.Update()
			{   
				if (i = position ){
					return allprofiles[i]
				} 
			}
        }
        input(){
            if (allprofiles:=this.Update()){
                msg:="Available Profiles:`n"
                loop, % allprofiles.MaxIndex()
                {
                    msg.=allprofiles[A_Index] "`n"
                }
            } else {
                msg:="this won't work`nthere are no profiles to load?"
            }
			InputBox, OutputVar, type a profile name to load, % msg ,, % Width, % Height, % X, % Y, % Locale, % Timeout, % firstprofile
			if !OutputVar
                return
            
            return OutputVar
		}
        Droplist(option=0){
			loop, % count:=(droplist:=this.Update()).MaxIndex()
			{
				if (A_Index = "1"){
				    drop:=droplist[A_Index]
                if option
                    drop.="|"
				} 
				if (A_Index > 1){
				drop.="|" . droplist[A_Index]
				}
			}
            droplist:=
			return drop
        }
        nameframe(profilename){
            framed:="D2RTM__" profilename
            return framed
        }
        retrieve(profilename){
            profilename:=this.nameframe(profilename)
            keys:=this.Get(profilename)
             return  keys
        }
    } 
    class bnet {
       ; bnet
        static logintitle:="Battle.net Login"
        static onlinetitle:="Battle.net"
        static exeid:="ahk_exe battle.net.exe"
        __New() {
            return
        }
        startBnet(){
            RunWait, "C:\Program Files (x86)\Battle.net\Battle.net.exe", "C:\Program Files (x86)\Battle.net",, bnetppid
            return bnetppid
        }
        movelogin(X=0,Y=0,title=""){
            if !title
                title:=this.exeid
            WinMove, % title,, % X, % Y
        }
        login(username,pw="",tabup=0){
            oldclip:=Clipboard
            Clipboard:=username
            if WinExist(this.logintitle)
                WinActivate, % this.logintitle
            if WinActive(this.exeid){
                if tabup{
                    send, +{tab}
                }
                send, ^a
                sleep, 500
                {
                    ;send, ^v
                    sendraw, % username
                    sleep, 500
                }
                send, ^a
                sleep, 500
                send, ^c
                sleep, 500
                if (username = Clipboard){
                    Send, {tab}
                    sleep 500
                    username:=
                    Clipboard:=oldclip
                    oldclip:=
                    this.pass(pw)
                    pw:=
                    } else {
                        return 0
                    }
                }
                return 0
        }
            
        pass(PW){
            clipboard:=PW
            sendraw, % PW
            PW:=
            sleep, 1000
            Send, {enter}
            return 1	
        }
        killBnet() {
            return this.killprocess("Battle.net.exe")
        }
        killAgent(){
            return this.killprocess("Agent.exe")
        }
        killprocess(exe){
            if (D2RTMcore.process.closeExe(exe)){
                while (D2RTMcore.process.PIDbyExe(exe) > 0) 
                {
                    D2RTMcore.process.closeExe(exe)
                }
            }
            return 1
        }
        StopAll(){
            while (!this.killBnet() and !this.killAgent())
            {
                sleep, 100
            }
            return 1
        }
        play(){
            play:="|<>0x0074E0@0.47$69.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs7szzzzzzzzz0D7zzzzzzzzs0szzzzzzzzzT77zzzzzzzzvssy3tyTzzzzT77U77Xzzzzvsss0swTzzzz0777bXbzzzzs1szswMzzzzz0z7U7n7zzzzvzsswy9zzzzzTz7D7sDzzzzvzss0z1zzzzzTz70bsTzzzzvzswAzXzzzzzzzzzzwzzzzzzzzzzzbzzzzzzzzzzUzzzzzzzzzzsDzzzzzzzzzzXzzzzzw"
            playnoregion:="|<>*168$71.zzzzzzzzzzzzzzzzzzzzzzzzzk0wDzzzzzzzzU0sTzzzzzzzz00kzzzzzzzzyDVVzzzzzzzzwT33kD7lzzzzsy670C73zzzzlwAA0ACDzzzzU0MMQQQTzzzz01kz0sEzzzzy0DVk1sXzzzzwTz33Xk7zzzzszy6C7kDzzzzlzwA0DUzzzzzXzsM0T1zzzzz7zks8z3zzzzzzzzzzyDzzzzzzzzzzsTzzzzzzzzzz0zzzzzzzzzzw3zzzzzzzzzzsDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
            playnoregionfound:=FindText(X, Y, 1047-150000, 667-150000, 1047+150000, 667+150000, 0, 0, Text)
            playfound:=FindText(X, Y, 375-150000, 643-150000, 375+150000, 643+150000, 0, 0, play)
            if (playfound or playnoregionfound)
            {
            FindText().Click(X, Y, "L")
            return 1
            } else {
                return 0
            }	
        }
        movewindow(){
            WinMove, Diablo II: Ressurected,, 0, 0, 1368, 768
        }
        
        verify(){
            verify:="|<>**50$46.4F00AME0P400nb01gzvzyTrWXUs4kHmCA1UH178sXaDCSMn608wttX4M0WHYWIFby9CH1MCAMYt45Uw1WHYMm2sC9CFXU"
            if (FindText(X, Y, 956-150000, 678-150000, 956+150000, 678+150000, 0, 0, verify))
            {
             FindText().Click(X, Y, "L")
            } else {
                return 0
            }
            
           


        }
        verifywayup(){
            wayup:="|<>**50$46.Qv3/FOuBnjqt5fiLAzPgKix+L1alOuqhNrG5fjOpjRMLixbCtN1Qta"
            while (!FindText(X, Y, 1066-150000, 486-150000, 1066+150000, 486+150000, 0, 0, wayup))
            {
             sleep, 1000
            }
            return 1
        }
        cats(){
            cat1:="|<>**50$69.4CA1k0010000Vn0Q000A000A6E70000U0011a1k00040008AkQ0000k0031Y7U0002000MMlw0000E00632BU0002100kkFg0000M00463BU00030001U9a00008800A1Aw00011s0X08Xs0008TU7k367U0011W080Mtw0008000033z0001U0000MRk000A0E001ks0000k00007r00003z00003U000000000000000000000000000000000000000004"
            cat2:=
            if (FindText(X, Y, 850-150000, 590-150000, 850+150000, 590+150000, 0, 0, cat1))
            {
                FindText().Click(X, Y, "L")
                return 1
            }
        }
        verified(){
            verified:="|<>**50$62.U00600C0608000k01k302000C00C1U0U001k01kk08000C00CM020001k01w00U000C00C0080001k000020000C00001U0001k0000w0000C0000P00001k000AE0000C0006400001k0031U0000C001UM00001k00k200000C00M0k00001k0A0400000C0601U00001k300M00000C3U02000001lk00k000007k02"
            if (ok:=FindText(X, Y, 933-150000, 582-150000, 933+150000, 582+150000, 0, 0, verified))
            {
            ; FindText().Click(X, Y, "L")
            return 1
            }
        }
        verifylogin(){
            verifylogin:="|<>**50$44.k0000H0A00004k31zXzVDzksBV8HUQA1k24s32SQsVCQlamP8HbgNAaG4tP6P9gVCKzbaC8HZUA1k24tM3Uq4VCKzzvz8Txk00XW00000A1U00001Us008"
            if (FindText(X, Y, 960-150000, 824-150000, 960+150000, 824+150000, 0, 0, verifylogin))
            {
                FindText().Click(X, Y, "L")
            }
        }
       ; end of inner bnet  
        class D2R extends D2RTMcore.bnet {
            Select(){
               if this.D2Runselected(){
                    sleep, 1000
                }
                if (this.D2Rselected()){
                    sleep, 1000
                    this.play()
                    return 1
                }
            }
            online(){
                online:="|<>0xF3F3F3@0.46$51.WMMV0El27z3Y8278EWMKV0Eh7yG2Q824sEOkFV0EX24"
                if (!FindText(X, Y, 1318-150000, 219-150000, 1318+150000, 219+150000, 0, 0, online)){
                    this.offline()
                    } else {
                        return 1
                    }
            }
            offline(){
                ;technically it's the online tab... but offline
                offline:="|<>#115@0.77$47.8VW41349z3Y8278EW5cE4/Ft89kU8HV2kEV0EV2E"
                if (FindText(X, Y, 1101-150000, 68-150000, 1101+150000, 68+150000, 0, 0, offline)){
                    FindText().Click(X, Y, "L")
                    return 1
                    }
            }
            Onlinegamecreation(){
                Onlinegamecreation:="|<>DFC790-000000$17.0Q00s0Tz1sC1UA608M0Qk0tU1lU310430MD1kDzU1k0308"
                if (FindText(X, Y, 542-150000, 725-150000, 542+150000, 725+150000, 0, 0, Onlinegamecreation))
                {
                    ;FindText().Click(X, Y, "L")
                    return 1
                }
            }
            Launch(title=""){
                if !title
                    title:="Diablo II: Resurrected"
            }
            D2Runselected(){
                D2R:="|<>**50$26.NTwEWPzq8WsTW8jvcW//v8Wmrm8gZoW/9R8WmLG8gZoW//T8Wmym8hvcW/hy8asxW/TyEWzzA9v073zQ3zs"
                if (FindText(X, Y, 870-150000, 337-150000, 870+150000, 337+150000, 0, 0, D2R))
                {
                FindText().Click(X, Y, "L")
                return 1
                }
            }
            D2Rselected(){
                D2Rselected:="|<>**50$26.8irsWPXq8hzt2/zwkbg0QDxkDz0000Dzzzw0000000000000000000000000000000000000000000000000003zzzz000000002"
                if (FindText(X, Y, 2151-150000, 242-150000, 2151+150000, 242+150000, 0, 0, D2Rselected))
                {
                ;FindText().Click(X, Y, "L")
                return 1
                }

            }
            kill(){
                this.killprocess("D2R.exe")
            }
            Start(exe="",dir="") {
                if !exe
                    exe:="C:\Program Files (x86)\Diablo II Resurrected\D2R.exe"
                if !dir
                dir:="C:\Program Files (x86)\Diablo II Resurrected"
                Run, %exe% , %dir%,, PID
                return PID
            }
            Title(title){
                return D2RTMcore.Window.title("Diablo II: Resurrected","D2R:" title)
            }
        } ;End of D2R
    } 
    class D2RTM extends D2RTMcore {
        __New(menukey=""){
            D2RTMcore.New()
            D2RTMcore := New D2RTMcore
            D2RMENU:= ObjBindMethod(this,"Show")
            if (menukey != "") {
            Hotkey, %menukey%, % D2RMENU, on
            } else {
                Hotkey, #LButton, % D2RMENU, on
            }
            this.Menu()
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
            this.UpdatedToken(SelectedProfile)
            this.bnet.D2R.kill()

            
            
        }
        UpdatedToken(SelectedProfile){
            while (!this.bnet.D2R.online() and !this.bnet.D2R.Onlinegamecreation())
            {
                sleep, 1000
            }
            return this.savetoken(SelectedProfile)
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
            sleep, 1000
            this.handle.close()
            this.bnet.D2R.title(SelectedProfile)
            result:=this.UpdatedToken(SelectedProfile)
            return result
        }
        RefreshAll(){
            Allprofiles:=this.profile.Update()
            for profile,name in Allprofiles
                this.Refreshtoken(name)
        }
        StartAll(){
            Allprofiles:=this.profile.Update()
            for profile,name in Allprofiles
            {

                if (this.StartToken(name))
                    break
            }
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
                for profile,name in Allprofiles
                {
                    menu_profile:=Allprofiles[A_Index]
                    menu, Launchers, add, % name, menu_launcher
                    menu, Refreshers, add, % name, menu_refresher
                    Menu, Tokens, Add, % name, menu_ProfileTokenSave
                }
                menu, Start, add, Launch, :Launchers
                menu, Refresh, add, Refresh, :Refreshers
                
                Menu, Start, Add, Token, starttoken
                Menu, Start, Add, All, StartAll
                menu, D2RTM, add, Start, :Start
            }
            if (ProfileCount){
                Menu, Profile, Add, Token, :Tokens
                Menu, Profile, Add, List, List
                menu, D2RTM, add, Refresh, :Refresh
                Menu, Refresh, Add, Token, Refreshtoken
                Menu, Refresh, Add, All, RefreshAll
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
} ;end of D2RTMcore

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
