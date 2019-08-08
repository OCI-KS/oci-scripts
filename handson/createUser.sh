#!/bin/bash

input=./data/users.tsv

lines=`cat ${input} | grep -c ''`
count=1
rm -f ${input}.new

while read row; do
  IFS="$(echo -e '\t')"
  set -- $row
  description=$1
  shortname=$2
  email=$3
  groups=`echo $4 | tr '|' '\n'`
  userid=$5
  password=$6
  unset IFS

  echo "+ Processing ${count} of ${lines} user(s): ${shortname}"

  userid=$(oci iam user list --all --query 'data[?"name"==`'${shortname}'`].id | [0]' --raw-output) &>/dev/null
  if [ "${userid}" = "" ]; then
    echo -n "    - creating user ${shortname} ..."
    userid=`oci iam user create --name ${shortname} --description="${description}" --query 'data.id' --raw-output`
    echo "done."
    echo "        - OCID: ${userid}"

    echo -n "    - issuing new password for ${shortname} ..."
    password=`oci iam user ui-password create-or-reset --user-id ${userid} --query 'data.password' --raw-output`
    echo "done."

  else
    echo "    - user ${shortname} exist. skipping user creation."
    echo "        - OCID: ${userid}"

  fi

  for group in ${groups}; do
    echo -n "    - adding user to the group ${group} ..."
    groupid=$(oci iam group list --all --query 'data[?"name"==`'${group}'`].id | [0]' --raw-output) &>/dev/null
    if [ -n "${groupid}" ]; then
      status=`oci iam group add-user --user-id ${userid} --group-id ${groupid}`
      echo "done."
    else
      echo "failed."
      echo "    - WARNING> group ${group} does not exist. please create first."
    fi

  done

  echo "${row}	${userid}	${password}" >>${input}.new
  echo ""
  count=`expr $count + 1`

done < ${input}

rm -f ${input}
mv ${input}.new ${input}
