{% include navigation.html%}

# Welcome

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/LICENSE)


scupPS is a User Portal for Microsoft Endpoint Configuration Mananger, previously called Microsoft System Center Configuration Manager.
It allows costcenter managers to approve software requests for their users using the builtin MEMCM Application Model Admin Approval Workflow.
The Portal is completely written in Powershell 7.0, based on the Powershell Webserver called [Pode](https://github.com/Badgerati/Pode).
The Web UI is served by a bootstrap derived template called [AdminLTE](https://github.com/ColorlibHQ/AdminLTE).

[![GetStarted](https://img.shields.io/badge/-Get%20Started!-green.svg?longCache=true&style=for-the-badge)](./Getting-Started/Installation)

## Features

* Completely built on PowerShell Core Version 7.0
* Support for native Single Sign On handled by the Internet Information Services (IIS) 
* Listen on a single or multiple IP address/hostnames
* Support for custom error pages
* Request and Response compression using GZip/Deflate
* Multi-thread support for incoming requests
* Ability to allow/deny requests from certain IP addresses and subnets
* No own datasource / database: Pulls all informations from MEMCM/SCCM and uses native capabilities
* **MEMCM / SCCM Support**
  * Supports all MEMCM/SCCM Versions starting from 1906
  * Tested on:
    * MEMCM 2002
    * MEMCM 1910
    * SCCM 1906
  * Limited functionality:
    * SCCM 1902
  * Works no matter if the Feature "Approve application requests for users per device" is enabled or not
  * Support for Application Supersedence, existing Approvals will be migrated to the superseeding Application
* **Application Approval Workflow**
  * *Supports all Application Model based Apps in MEMCM/SCCM*
  * **Manager View**
    * View pending Approval Requests which were started by your users using the native Software Center
    * View the history of Approval Requests for your Costcenter
    * Approve, Deny or Revoke Requests of Software for your Costcenter
  * **User View**
    * View your own requests and their Status
  * **Admin View**
    * See all requests and approve, deny or revoke them
* **Helpdesk Functions**
  * **List Client Details**: View a hardware summary of a client (Manufacturer, Model, Serialnumber, Name, Domain, Memory, Disks and Config Manager Client details)
  * **List Computers**: View computers, their primary user, last activity, last AD Site and the last logged on User per Collection
  * **List Computer Summary**: View a list of device models sorted by count
  * **List Software**: View installed Updates of a client
  * **List Task Sequence Status**: View the status of currently running or recently run task sequences
  * **List Updates**: View installed Software on a client


## Quick Look!

[![GetStarted (Application Approval Workflow)](https://img.shields.io/badge/-Get%20Started%20(Approval%20Workflow)!-green.svg?longCache=true&style=for-the-badge)](./Look-and-Feel/Approval-Workflow)

[![GetStarted (Helpdesk Functions)](https://img.shields.io/badge/-Get%20Started%20(Helpdesk%20Functions)!-blue.svg?longCache=true&style=for-the-badge)](./Look-and-Feel/Helpdesk)
