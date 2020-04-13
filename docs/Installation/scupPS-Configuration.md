{% include navigation.html%}

# scupPS Configuration Steps
This document describes the main configuration steps for scupPS

## Initial Setup
After setting up the IIS Site and cloning scupPS into the webroot, start the IIS App Pool and browse to the scupPS URL.
You will now be asked to configure the basic settings required to run scupPS.
The Wizard will verify settings like the Site Server and Site Code and won't let you continue without having them being tested successfully.
After you're logged into scupPS, set the helpdesk Group under "Admin" -> "Configuration Roles". You can set this group to the same group you're using as admin group.

You can update all settings anytime either offline in the "states.json" file while scupPS/Pode is stopped or online in under the menu point "Admin" -> "Configuration - General".