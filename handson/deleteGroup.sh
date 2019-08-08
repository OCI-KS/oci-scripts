#!/bin/bash

input=./data/groups.tsv

lines=`cat ${input} | grep -c ''`
count=1
rm -f ${input}.new

while read row; do
  IFS="$(echo -e '\t')"
  set -- $row
  name=$1
  description=$2
  unset IFS

  echo "+ Processing ${count} of ${lines} group(s): ${name}"

  groupid=$(oci iam group list --all --query 'data[?"name"==`'${name}'`].id | [0]' --raw-output)

  if [ "${groupid}" != "" ]; then
    echo -n "    - deleting group ${name} ..."
    status=`oci iam group delete --group-id ${groupid} --force`
    echo "done."
    echo "        - OCID: ${groupid}"

    echo "${name}       ${description}" >>${input}.new

  else
    echo "    - group ${name} does not exist. skipping policy deletion."

    echo "${row}" >>${input}.new

  fi

  echo ""
  count=`expr $count + 1`

done < ${input}

rm -f ${input}
mv ${input}.new ${input}
