# scupPS Configuration Steps
This document describes the main configuration steps for scupPS

## Create config files
Create a copy of the following files and remove the .template extension:
```
server.ps1.template
```
```
views\includes\core\config.ps1.template
```

## Configure the server.ps1
Adjust the String "YourOwnLittleSecret" to a random secret, this secret is used to generate the session cookies for Pode.

## Adjust the config.ps1
Adjust the values in the config.ps1 to your needs, those are used by all functions of scupPS.
All values in there are commented and should be self-describing. Incase of questions feel free to raise an Issue on the Github Repository.