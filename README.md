= ldapsearch.sh =


ldapsearch.sh search LDAP and convert time values to human readable
format and decode base64 encoded values. It helps administrators in
reading Active Directory LDAP values in bash shell.



= Prerequisites =


U must have installed ldapsearch tool.

In Ubuntu install ldap-utils.
$ sudo apt install ldap-utils

If u use Kerberos, install package krb5-user.
$ sudo apt install krb5-user



= How to use =


**Example**

  __Search User__

  Account:              ldapsearch.sh -n "username"
  Enabled Account:      ldapsearch.sh -s e -n "\*username\*"
  Disabled Account:     ldapsearch.sh -s d -n "\*username\*"
  Contact Info:         ldapsearch.sh -s e -a "title displayName department streetAddress telephoneNumber employeeID mail" -n "\*username\*"
  Contact Info2:        ldapsearch.sh -s e -a "title displayName department streetAddress telephoneNumber employeeID mail sAMAccountName userPrincipalName wWWHomePage" -n "\*username\*"
  Password Last Set:    ldapsearch.sh -s e -a "sAMAccountName pwdLastSet" -n "\*username\*"


  __Search Computer__

  Account:              ldapsearch.sh -n "computer$"
  Disabled Account:     ldapsearch.sh -s d -n "\*computer\*$"
  Created/Changed:      ldapsearch.sh -a "sAMAccountName whenCreated whenChanged" -n "computer$"


  __Search Group__

  Group:                ldapsearch.sh -n "%group"
  Enabled Group:        ldapsearch.sh -s e -n "%\*group\*"
  Predefined Filter:    ldapsearch.sh -g empty

