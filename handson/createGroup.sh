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
  groupid=$3
  unset IFS

  echo "+ Processing ${count} of ${lines} group(s): ${name}"

  echo -n "    - creating group ${name} ..."
  groupid=`oci iam group create --name ${name} --description="${description}" --query 'data.id' --raw-output`
  echo "done."
  echo "        - OCID: ${groupid}"

  echo "${row}	${groupid}" >>${input}.new
  echo ""
  count=`expr $count + 1`

done < ${input}

rm -f ${input}
mv ${input}.new ${input}
