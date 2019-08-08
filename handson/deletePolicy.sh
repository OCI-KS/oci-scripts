#!/bin/bash

input=./data/policies.tsv

lines=`cat ${input} | grep -c ''`
count=1
rm -f ${input}.new

while read row; do
  IFS="$(echo -e '\t')"
  set -- $row
  name=$1
  description=$2
  statements=$3
  unset IFS

  echo "+ Processing ${count} of ${lines} policy(s): ${name}"

  policyid=$(oci iam policy list --all --query 'data[?"name"==`'${name}'`].id | [0]' --raw-output)

  if [ "${policyid}" != "" ]; then
    echo -n "    - deleting policy ${name} ..."
    status=`oci iam policy delete --policy-id ${policyid} --force`
    echo "done."
    echo "        - OCID: ${policyid}"

    echo "${name}	${description}	${statements}" >>${input}.new

  else
    echo "    - policy ${name} does not exist. skipping policy deletion."
    echo "        - OCID: ${policyid}"

    echo "${row}" >>${input}.new

  fi

  echo ""
  count=`expr $count + 1`

done < ${input}

rm -f ${input}
mv ${input}.new ${input}
