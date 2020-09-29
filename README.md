# ldapsearch.sh


ldapsearch.sh search LDAP and convert time values into human readable
format and decode base64 encoded values. It helps administrators in
reading Active Directory LDAP values in bash shell.



# Prerequisites


You must have installed ldapsearch tool.


In Ubuntu install ldap-utils.

$ sudo apt install ldap-utils

GSSAPI dependency.

$ sudo apt install libsasl2-modules-gssapi-mit


If u use Kerberos, install package krb5-user.

$ sudo apt install krb5-user



# How to use


**Example**


  *Search User*

  Account:              `ldapsearch.sh -n "username"`

  Enabled Account:      `ldapsearch.sh -s e -n "*username*"`

  Disabled Account:     `ldapsearch.sh -s d -n "*username*"`

  Contact Info:         `ldapsearch.sh -s e -a "title displayName department streetAddress telephoneNumber employeeID mail" -n "*username*"`

  Contact Info2:        `ldapsearch.sh -s e -a "title displayName department streetAddress telephoneNumber employeeID mail sAMAccountName userPrincipalName wWWHomePage" -n "*username*"`

  Password Last Set:    `ldapsearch.sh -s e -a "sAMAccountName pwdLastSet" -n "*username*"`



  *Search Computer*


  Account:              `ldapsearch.sh -n "computer$"`

  Disabled Account:     `ldapsearch.sh -s d -n "*compute*$"`

  Created/Changed:      `ldapsearch.sh -a "sAMAccountName whenCreated whenChanged" -n "computer$"`



  *Search Group*


  Group:                `ldapsearch.sh -n "%group"`

  Enabled Group:        `ldapsearch.sh -s e -n "%*group*"`

  Predefined Filter:    `ldapsearch.sh -g empty`

