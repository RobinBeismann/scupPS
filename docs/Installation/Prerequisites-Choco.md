# IIS

As mentioned earlier this Portal is hosted on [Pode](https://github.com/Badgerati/Pode) which is in this case hosted on IIS.
IIS handles the Authentication in this scenario, this is called "Windows Authentication" in Terms of IIS.
Most of this page is copied from the [IIS Hosting Documentation on the Pode Website](https://badgerati.github.io/Pode/Hosting/IIS/).

## Requirements
* Internet Information Services (IIS)
* ASP.NET Core Hosting Package for IIS
* Powershell Core 7.0
* Pode Module

To start with you'll need to have IIS (or IIS Express) installed:

```powershell
Install-WindowsFeature -Name Web-Server -IncludeManagementTools -IncludeAllSubFeature
```

Next you'll need to install ASP.NET Core Hosting:

```powershell
choco install dotnetcore-windowshosting -y
```

You'll also need to use PowerShell Core (*not Windows PowerShell!*):

```powershell
choco install pwsh -y
```

Finally, you'll need to have Pode installed under PowerShell Core:

```powershell
pwsh -c "Install-Module Pode -Scope AllUsers"
```

Reset the IIS for the .NET Core Subsystem to get active
```cmd
iisreset /noforce
```


* [Host ASP.NET Core on Windows with IIS \| Microsoft Docs](https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-3.1)