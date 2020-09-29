#!/bin/bash
#
# author:       Matej Fabijanic <root4unix@gmail.com>
#
# description:  LDAP Search
#

work="$(cd $(dirname $0) && pwd)"
config="$work/ldapsearch.conf"


if [ -f "$config" ]; then
  . $config
else
  echo
  echo "Configuration file $config does not exists."
  echo
  exit 1
fi


# Text: bold, normal
t_b="\033[1m"
t_u="\033[4m"
t_n="\033[0m"


#----------------------------- Functions
usage_arg_name() {
  echo -e "  -n ${t_u}name${t_n}             User, computer or group account"
  echo "     username           - username"
  echo "     computername$      - computer name"
  echo "     %group             - group"
}

usage_arg_filter_group() {
  echo -e "  -g ${t_u}group_filter${t_n}     Group Filters"
  echo "     empty              - All empty groups"
  echo "     changed            - All groups which were changed since Dec 31 2008"
}

usage_arg_filter() {
  echo -e "  -f ${t_u}filter${t_n}     Group Filters"
  echo "     (filter)           - for example filter"
}

usage_arg_account_status() {
  echo -e "  -s ${t_u}account_status${t_n}   Account status (default: a (all))"
  echo "     e                  - enabled"
  echo "     d                  - disabled"
  echo "     a                  - all"
}

usage_arg_ldap_attr() {
  echo -e "  -a ${t_u}ldap_attr${t_n}        LDAP attributes, overrides predefined attributes"
  echo "     sAMAccountName     - for example sAMAccountName"
}

example_user() {
  echo -e "  ${t_u}Search User${t_n}"
  echo
  echo "  Account:              $script -n \"username\""
  echo "  Enabled Account:      $script -s e -n \"*username*\""
  echo "  Disabled Account:     $script -s d -n \"*username*\""
  echo "  Contact Info:         $script -s e -a \"title displayName department streetAddress telephoneNumber employeeID mail\" -n \"*username*\""
  echo "  Contact Info2:        $script -s e -a \"title displayName department streetAddress telephoneNumber employeeID mail sAMAccountName userPrincipalName wWWHomePage\" -n \"*username*\""
  echo "  Password Last Set:    $script -s e -a \"sAMAccountName pwdLastSet\" -n \"*username*\""
}

example_computer() {
  echo -e "  ${t_u}Search Computer${t_n}"
  echo
  echo "  Account:              $script -n \"computer$\""
  echo "  Disabled Account:     $script -s d -n \"*computer*$\""
  echo "  Created/Changed:      $script -a \"sAMAccountName whenCreated whenChanged\" -n \"computer$\""
}

example_group() {
  echo -e "  ${t_u}Search Group${t_n}"
  echo
  echo "  Group:                $script -n \"%group\""
  echo "  Enabled Group:        $script -s e -n \"%*group*\""
  echo "  Predefined Filter:    $script -g empty"
}

usage() {
  echo
  echo -e "${t_b}Usage${t_n}"
  echo
  echo -e "  ${t_b}$script${t_n} [options]"
  echo
  echo -e "${t_b}Option${t_n}"
  echo
  usage_arg_name
  echo
  usage_arg_filter_group
  echo
  usage_arg_account_status
  echo
  usage_arg_ldap_attr
  echo
  echo "  -d                  Debug mode"
  echo
  echo "  -h                  Help"
  echo
}

# Convert AD date
convert_ad_date() {
  ad_date="$1"
  #ad_date=131792256743363195;
  LC_ALL=C date --rfc-3339=seconds -d "01/01/1601 UTC $(let ad_date=ad_date/10000000; echo $ad_date) seconds"
}

# atributes for time conversion (AD -> date)
if [ -z "$attr_to_date" ]; then
  attr_to_date="badPasswordTime|lastLogon|lockoutTime|pwdLastSet|accountExpires|lastLogonTimestamp"
fi

ldap_search() {
  $LDAPSEARCH 2>&1 | grep -v "^SASL" | while read line
  do
    # if line contains "::" then decode base64
    if (echo "$line" | grep -q ":: "); then
      echo -n "$(echo "$line" | awk -F "::" '{print $1": "}')"
      echo "$line" | awk -F ":: " '{print $2}' | base64 -d
      echo
    else
      attr_1="$(echo "$line" | awk -F ":" '{print $1}')"
      if (echo "$attr_1" | grep -q -E "($attr_to_date)"); then
        attr_2="$(echo "$line" | awk -F ": " '{print $2}')"
        # radi konverziju ako nije "0"
        if [[ $attr_2 != "0" ]]; then
          attr_2="$(convert_ad_date "$attr_2")"
        fi
        echo "$attr_1: $attr_2"
      else
        echo "$line"
      fi
    fi
    # awk makne sve sto je nasao da pocinje s "# ref" i liniju iza te
  done | awk -v skip=-1 '/^# ref/ { skip = 1 } skip-- >= 0 {next } 1'
}


#----------------------------- Main
account_type=""     # Account Type: user, group, computer
opt=""
account_name=""     # Account (Computer/User) Name
account_status="a"  # Account Status (default: a (all))
ldap_attr=""        # LDAP atributi

filter_group=""
filter=""           # dodatni filter

while getopts "n:s:a:g:f:hd" opt; do
  case $opt in
    n)  account_name=$OPTARG  ;;
    s)  account_status=$OPTARG  ;;
    a)  ldap_attr="$OPTARG" ;;
    g)  filter_group="$OPTARG" ;;
    f)  filter="$OPTARG" ;;
    h)  help=1;;
    d)  debug=1  ;;
    ?)
      echo "Unknown option $opt $OPTARG."
      exit 1
      ;;
  esac
done
shift $(($OPTIND - 1))
script="$(basename $0)"

# Help
if [[ $help -eq 1 ]]; then
  cmd1="$1"
  cmd2="$2"
  if [[ $debug -eq 1 ]]; then
    echo "CMD1: $cmd1"
    echo "CMD2: $cmd2"
  fi

  case "$cmd1" in
    help)
      usage
      [ -z "$REALM" ] && local REALM="example.com"
      echo
      echo "Kerberos Authentication"
      echo "======================="
      echo
      echo "  Obtain and cache Kerberos ticket-granting ticket"
      echo "    $ kinit username@$REALM"
      echo
      echo "  List cached Kerberos tickets"
      echo "    $ klist"
      echo
      ;;
    usage)
      echo
      echo -e "${t_b}Usage${t_n}"
      echo
      if [[ -z "$cmd2" ]]; then
        echo -e "  $script -h usage ${t_u}option${t_n}"
        echo
        echo -e "${t_b}Option${t_n}"
        echo "  -n          User, computer or group account"
        echo "  -g          Group Filters"
        echo "  -f          Filter"
        echo "  -a          LDAP attributes, overrides predefined attributes"
        echo "  -s          Account status (default: a (all))"
      else
        echo -e "  $script ${cmd2} ${t_u}option${t_n}"
        echo
        case "$cmd2" in
          "-n") usage_arg_name  ;;
          "-g") usage_arg_filter_group  ;;
          "-f") usage_arg_filter  ;;
          "-a") usage_arg_ldap_attr ;;
          "-s") usage_arg_account_status  ;;
          *)  echo "No such option \"${cmd2}\"." ;;
        esac
      fi
      ;;
    example)
      echo
      echo -e "${t_b}Example${t_n}"
      echo
      if [[ -z "$cmd2" ]]; then
        echo -e "  $script -h example ${t_u}option${t_n}"
        echo
        echo -e "${t_b}Option${t_n}"
        echo "  user        Search User"
        echo "  computer    Search Computer"
        echo "  group       Search Group"
      else
        case "$cmd2" in
          user)     example_user  ;;
          computer) example_computer  ;;
          group)    example_group ;;
          *)  echo "No such option \"${cmd2}\"." ;;
        esac
      fi
      ;;
    *)
      echo
      echo -e "${t_b}Help${t_n}"
      echo
      echo -e "  $script -h ${t_u}option${t_n}"
      echo
      echo "    help         Help"
      echo "    usage        Usage"
      echo "    example      Example"
      ;;
  esac

  echo
  exit 0
fi

if [ "$account_status" != "a" ] && [ "$account_status" != "e" ] && \
  [ "$account_status" != "d" ]; then
  echo
  echo "Account Status is not \"a\" or \"e\" or \"d\"."
  echo
  exit 1
fi

# You must set account_name if group filter is empty
if [ -z "$filter_group" ]; then
  if [ -z "$account_name" ]; then
    usage
    exit 1
  fi
fi

if [ ! -z "$filter_group" ]; then
  # ako je definiran filter za grupu "arg -g" onda je account_type grupa
  account_type="g"
  case "$filter_group" in
    empty)    FILTER="${FILTER}(!(member=*))" ;;
    changed)  FILTER="${FILTER}(whenChanged>=20081231000000.0Z)" ;;
    *)
      usage_arg_filter_group
      echo
      exit 1
      ;;
  esac
fi

if [ ! -z "$filter" ]; then
  FILTER="${FILTER}${filter}"
fi

# Account Type detection: computer, user, group
if [ -z "$account_type" ]; then
  if (echo "$account_name" | grep -q '\$$'); then
    # Computer
    account_type="c"
  elif (echo "$account_name" | grep -q "^%"); then
    # Group
    account_type="g"
  else
    # User
    account_type="u"
  fi
fi

case "$account_type" in
  u)  FILTER="(sAMAccountType=805306368)${FILTER}" ;;
  c)  FILTER="(sAMAccountType=805306369)${FILTER}" ;;
  g)
    # remove "%" from account_name because of LDAP search filter
    # we use % only for account type detection
    # if group filter "arg -g" is defined you can use account_name
    # without character %
    if (echo "$account_name" | grep -q "%"); then
      account_name="$(echo "$account_name" | awk -F "%" '{print $2}')"
    fi
    FILTER="(sAMAccountType=268435456)${FILTER}"
    ;;
esac

# LDAP Filter: sAMAccountName
[ ! -z "$account_name" ] && FILTER="${FILTER}(sAMAccountName=${account_name})"

# UserAccountControl: enabled, disabled, all
case "$account_status" in
  e|enabled)  FILTER="${FILTER}(!(UserAccountControl:1.2.840.113556.1.4.803:=2))" ;;
  d|disabled) FILTER="${FILTER}(UserAccountControl:1.2.840.113556.1.4.803:=2)" ;;
  a|all)      FILTER="${FILTER}" ;;
  *)
    usage
    exit 1
  ;;
esac

# Filter - dodani filteri u (&)
FILTER="(&${FILTER})"

if [ "$auth" = "gssapi" ]; then
  # GSSAPI
  if [[ -z "$REALM" ]]; then
    echo
    echo "Configure REALM in configuration file."
    echo
    exit 1
  fi
  #ldapsearch -H ldaps://dc.example.com -b "dc=example,dc=hr" -O maxssf=0 cn
  COMMAND="$COMMAND -H ldaps://$LDAP_SERVER -b $BASEDN -O maxssf=0 -o ldif-wrap=no"
elif [ "$auth" = "simple" ]; then
  # Simple Auth: User/Pass
  COMMAND="$COMMAND -x -b $BASEDN -H ldap://$LDAP_SERVER -D $BINDDN -w $BINDPW -o ldif-wrap=no"
else
  echo "Auth type is not supported. Supported auth type are gssapi and simple."
  exit 1
fi

LDAPSEARCH="$COMMAND $FILTER $ldap_attr"

if [[ $debug -eq 1 ]]; then
  echo "Server:           $LDAP_SERVER"
  echo
  echo "Account Name:     $account_name"

  echo -n "Account Status:   $account_status    "
  case $account_status in
    a)  echo "- All"  ;;
    e)  echo "- Enabled"  ;;
    d)  echo "- Disabled" ;;
  esac

  echo -n "Account Type:     $account_type    "
  case $account_type in
    u)  echo "- User Account" ;;
    c)  echo "- Computer Account" ;;
    g)  echo "- Group" ;;
  esac

  echo
  echo "LDAP Filter:      $FILTER"
  echo "LDAP Attributes:  $ldap_attr"
  echo "LDAP Search:      $COMMAND \"$FILTER\" $ldap_attr"
  echo
fi

echo
echo -e "${t_b}Active Directory${t_n}"
echo "==================="
echo
ldap_search

