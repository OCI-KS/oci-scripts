#!/bin/bash

datadir=./data

#tenancyid="ocid1.tenancy.oc1..aaaaaaaatonm3amrk6mwbfknuyub4hy5c2psgrv6mdlbd2db2gotz5gqwjia"
tenancyid="ocid1.tenancy.oc1..aaaaaaaa3mb7wrcy2ls3u3jsy2soq5ck3lc3q4mczitpdaymbuazc5tkguca"
input=${datadir}/compartments.tsv

lines=`cat ${input} | grep -c ''`
count=1
rm -f ${input}.new

while read row; do
  IFS="$(echo -e '\t')"
  set -- $row
  name=$1
  description=$2
  parent=$3
  compartmentid=$4
  unset IFS

  echo "+ Processing ${count} of ${lines} compartment(s): ${description}"
  go=1

  compartmentid=$(oci iam compartment list --compartment-id-in-subtree true --all --query 'data[?"name"==`'${name}'`].id | [0]' --raw-output) &>/dev/null
  compartmentstate=$(oci iam compartment list --compartment-id-in-subtree true --all --query 'data[?"name"==`'${name}'`]."lifecycle-state" | [0]' --raw-output) &>/dev/null

  if [ "${parent}" = "tenancy" ]; then
    parentid=${tenancyid}
    parentstate=ACTIVE
  else
    parentid=$(oci iam compartment list --compartment-id-in-subtree true --all --query 'data[?"name"==`'${parent}'`].id | [0]' --raw-output) &>/dev/null
    parentstate=$(oci iam compartment list --compartment-id-in-subtree true --all --query 'data[?"name"==`'${parent}'`]."lifecycle-state" | [0]' --raw-output) &>/dev/null
  fi

  if [ "${parentid}" = "" ]; then
    echo "    - ERROR: parent compartment ${parent} does not exist. skipping compartment creation."
    echo "        - OCID: ${parentid}"
    echo "        - Status: ${parentstate}"
    go=0
  elif [ "${parentstate}" != "ACTIVE" ]; then
    echo "    - ERROR: parent compartment ${parent} is not active. skipping compartment creation."
    echo "        - OCID: ${parentid}"
    echo "        - Status: ${parentstate}"
    go=0
  fi

  if [ "${compartmentid}" = "" ]; then
    echo "    - compartment ${name} does not exist."
    go=1
  elif [ "${compartmentstate}" = "ACTIVE" ]; then
    echo "    - compartment ${name} exist and active. skipping compartment creation."
    echo "        - OCID:  ${compartmentid}"
    echo "        - STATE: ${compartmentstate}"
    go=0
  else
    echo "        - OCID:  ${compartmentid}"
    echo "        - STATE: ${compartmentstate}"
    go=0

  fi

  if [ ${go} -eq 1 ]; then
    echo -n "    - creating compartment ${name} ..."
    compartmentid=`oci iam compartment create --compartment-id ${parentid} --name ${name} --description="${description}" --query 'data.id' --raw-output`
    echo "done."
    echo "        - OCID: ${compartmentid}"

    echo "${row}	${compartmentid}" >>${input}.new
  else
    echo "${row}" >>${input}.new
  fi

  echo ""
  count=`expr $count + 1`

done < ${input}

rm -f ${input}
mv ${input}.new ${input}
