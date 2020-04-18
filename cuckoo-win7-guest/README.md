# Cuckoo Windows 7 Guest VM

This document describes a Windows 7 Guest VM.

#### Login Info

```
User Name: cuckoo-win7-guest
Password:  password
```

#### System Info

```
Location: ESXi/vSphere
IP Address: 10.32.10.x (static)
Subnet mask: 255.255.255.0
Default gateway: 10.32.10.x
Preferred DNS Server: 10.32.x.x
```

## Additional Software

I used [Ninite](https://ninite.com) to install additional software:

* Chrome
* Firefox
* Notepad++
* Visual Studio Code
* Java 8
* Silverlight
* Air
* Shockwave
* Foxit Reader
* OpenOffice

Additionally, Python 2.7.15 was installed as well as:

* Pillow

### Configuration Settings

The following configuration settings were made on the Windows 7 Guest VM:

* Disabled Windows Firewall (Manually)
* Added the Cuckoo Agent to the `cuckoo-win7-guest` user's Startup folder
** [agent.py](agent/agent.py)
** Startup Folder is located here: `“C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup”`
* In gpedit.msc disable Windows Updates by navigating to `Computer Configuration > Administrative Templates > Windows Components\Windows Update`, double-click `Configure Automatic Updates`, set it to `Enabled` and set to `Notify for download and notify for install`.
* In gpedit.msc disable UAC by navigating to `Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > Security Options` and make these changes:
** `User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode` - right click policy setting, click Properties. Check the box Define this policy setting and choose `Elevate without prompting`.
** `User Account Control: Detect application installations and prompt for elevation` - right-click policy setting, click Properties. Check the box Define this policy setting and choose `Disabled`.
** `User Account Control: Run all administrators in Admin Approval Mode` - right-click policy setting, click Properties. Check the box Define this policy setting and choose `Disabled`.
* In gpedit.msc disable the firewall by navigating to `Computer Configuration > Administrative Templates > Network > Network connections > Windows Firewall > Domain Profile > Windows Firewall` and change `Protect all network connections` to `Disabled`.
* Finally, run the following commands in an administrative prompt.
** Set the VM guest to auto-login with the provided username and password.
```
reg add "hklm\software\Microsoft\Windows NT\CurrentVersion\WinLogon" /v DefaultUserName /d cuckoo-win7-guest /t REG_SZ /f
reg add "hklm\software\Microsoft\Windows NT\CurrentVersion\WinLogon" /v DefaultPassword /d password /t REG_SZ /f
reg add "hklm\software\Microsoft\Windows NT\CurrentVersion\WinLogon" /v AutoAdminLogon /d 1 /t REG_SZ /f
```
** Allow Remote RPC connections to this machine:
```
reg add "hklm\system\CurrentControlSet\Control\TerminalServer" /v AllowRemoteRPC /d 0x01 /t REG_DWORD /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /d 0x01 /t REG_DWORD /f
```
