#!/bin/bash
#
# Copyright 2014(c) The Ontario Institute for Cancer Research. All rights reserved.
#
# Description:
#   internal use for the other scripts for setting the environment
#

# Prolog
set -o nounset
set -o errexit

EXPORTHOMEDIR=`dirname $0`/..; export EXPORTHOMEDIR

JOB_USER=downloader
E_BADARGS=65

if [[ $# -ne 2 && $# -ne 3 ]]
then
  echo "Usage: `basename $0` <release name> <Directory containing json directories> [<comma separated list of data types>]"
  echo "Example: `basename $0` r12 /icgc/etl/dcc-release-r--prod-06d-23-1 # process all data types"
  echo "Example: `basename $0` r12 /icgc/etl/dcc-release-r--prod-06d-23-1 ssm,meth # process ssm and meth only"
  exit $E_BADARGS
fi

release=$1
source=$2

declare -A typeMappings
typeMappings=(["ssm"]="ssm_open,ssm_controlled" 
              ["ssm_open"]="ssm_open" 
              ["ssm_controlled"]="ssm_controlled" 
              ["donor"]="clinical,clinicalsample" 
              ["clinical"]="clinical" 
              ["clinicalsample"]="clinicalsample" 
              ["sgv"]="sgv_controlled" 
              ["sgv_controlled"]="sgv_controlled" 
              ["pexp"]="pexp" 
              ["mirna_seq"]="mirna_seq" 
              ["meth_seq"]="meth_seq"
			  ["meth_array"]="meth_array" 
              ["jcn"]="jcn" 
              ["exp_seq"]="exp_seq"
              ["exp_array"]="exp_array"  
              ["cnsm"]="cnsm" 
              ["stsm"]="stsm")

declare -a datatypes="ssm_open,ssm_controlled,sgv_controlled,pexp,mirna_seq,meth_seq,meth_array,jcn,exp_seq,exp_array,clinical,clinicalsample,cnsm,stsm"

if [ $# -eq 3 ]
then
  datatypes=$3
fi

logfile=${EXPORTHOMEDIR}/logs/exporter.ec

IFS=',' read -a types <<< "$datatypes"

datatypes=""
for type in "${types[@]}"
do
	datatypes="${datatypes},${typeMappings["${type//[[:blank:]]/}"]}"
done

datatypes=${datatypes:1}

IFS=',' read -a types <<< "$datatypes"

#export HBASE_HOME=/usr/lib/hbase
export HADOOP_USER_NAME=${JOB_USER}
#export HADOOP_CLASSPATH=”`/usr/lib/hbase/bin/hbase classpath`:$HADOOP_CLASSPATH”
export HBASE_CONF_DIR="/etc/hbase/conf"
export PIG_USER_CLASSPATH_FIRST=true
export PIG_CLASSPATH="${HBASE_CONF_DIR}:${EXPORTHOMEDIR}/lib/dcc-etl-exporter.jar:`hbase classpath`"


#logging
umask 002
export PIG_OPTS=-Dpython.verbose=warning