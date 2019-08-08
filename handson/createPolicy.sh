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
  policyid=$4
  unset IFS

  echo "+ Processing ${count} of ${lines} policy(s): ${name}"

  policyid=$(oci iam policy list --all --query 'data[?"name"==`'${name}'`].id | [0]' --raw-output) &>/dev/null
  if [ "${policyid}" = "" ]; then
    echo -n "    - creating policy ${name} ..."
    policyid=`oci iam policy create --name "${name}" --description "${description}" --statements "${statements}" --query 'data.id' --raw-output`
    echo "done."
    echo "        - OCID: ${policyid}"

    echo "${row}	${policyid}" >>${input}.new

  else
    echo "    - policy ${name} exist. skipping policy creation."
    echo "        - OCID: ${policyid}"

    echo "${row}" >>${input}.new

  fi

  echo ""
  count=`expr $count + 1`

done < ${input}

rm -f ${input}
mv ${input}.new ${input}
