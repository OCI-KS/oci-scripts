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
  groups=$4
  unset IFS

  echo "+ Processing ${count} of ${lines} user(s): ${shortname}"

  userid=$(oci iam user list --all --query 'data[?"name"==`'${shortname}'`].id | [0]' --raw-output)
  groupids=$(oci iam user list-groups --all --user-id ${userid} --query 'join(`|`, data[].id)' --raw-output | tr '|' '\n')

  if [ "${userid}" != "" ]; then
    for groupid in $groupids; do
      group=`oci iam group get --group-id ${groupid} --query 'data.name' --raw-output`
      echo -n "    - removing user from group ${group} ..."
      `oci iam group remove-user --user-id ${userid} --group-id ${groupid} --force`
      echo "done."

    done

    echo -n "    - deleting user ${shortname} ..."
    status=`oci iam user delete --user-id ${userid} --force`
    echo "done."
    echo "        - OCID: ${userid}"

    echo "${description}	${shortname}	${email}	${groups}" >>${input}.new

  else
    echo "    - user ${name} does not exist. skipping user deletion."
    echo "        - OCID: ${policyid}"

    echo "${row}" >>${input}.new

  fi

  echo ""
  count=`expr $count + 1`

done < ${input}

rm -f ${input}
mv ${input}.new ${input}
