{% include navigation.html%}

## Server

The first thing you'll need to do so IIS can host your server. 
scupPS already delivers a web.config which includes the required settings: 
```xml
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="pwsh.exe" arguments=".\server.ps1" stdoutLogEnabled="true" stdoutLogFile=".\logs\stdout" hostingModel="OutOfProcess"/>
    </system.webServer>
  </location>
</configuration>
```

Once done, you can setup IIS in the normal way:

* Create an Application Pool
  * Chose an Application Pool Identity that has read/write access the Application Approval Class in MEMCM/SCCM and also basic read access to the hardware inventory for the update and software list.
  * If you wish to use the builtin task sequence monitor, then you also need to give that account read access to the task sequenceclass 
* Create a website, and set the physical path to the root directory of your scupPS folder
* Setup a binding (something like HTTP on *:8080 - IP Address can be anything), SSL recommended

## IIS Authentication
Setup Windows authentication on the IIS Website by going to the newly created Website in the IIS Manager, clicking Authentication and then enable Windows Authentication and disable Anonymous Authentication.
