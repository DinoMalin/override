#!/bin/bash

if ! which sshpass 2>&1 >/dev/null; then
	echo "error: sshpass not installed" 1>&2
	exit 1
fi

NAME=Rainfall

MAC=$(VBoxManage showvminfo $NAME \
	| grep "NIC 1" | awk '{print $4}' | sed 's/../&:/g' | sed 's/:,//')
IP=$(arp -a | grep -i $MAC | awk '{print $2}' | sed 's/(\([^)]*\))/\1/')

get_flag() {
	PREFIX="level"
	LEVEL=$1

	if [[ $1 == b* ]]; then
		LEVEL=$(echo $1 | cut -c 2)
		PREFIX="bonus"
	fi

	if [[ $PREFIX == "bonus" &&  $LEVEL == "0" ]]; then
		LEVEL="9"
		PREFIX="level"
	else
		LEVEL=$(($LEVEL-1))
	fi

	head $PREFIX$LEVEL/expl | head -n 1 | awk '{print $2}'
}

get_binary() {
	PREFIX="level"
	LEVEL="$1"

	if [[ $1 == b* ]]; then
		LEVEL=$(echo $1 | cut -c 2)
		PREFIX="bonus"
	fi

	FLAG=$(get_flag $1)
	if [ -z $FLAG ]; then
		exit 1
	fi

	mkdir -p $PREFIX$LEVEL
	sshpass -p $FLAG scp -P 4242 $PREFIX$LEVEL@$IP:$PREFIX$LEVEL $PREFIX$LEVEL
}

if [ $1 = "connect" ]; then
	if [ -z $2 ]; then
		echo "usage: $0 connect <level>" 1>&2
		exit 1
	fi

	FLAG=$(get_flag $2)
	if [ -z $FLAG ]; then
		exit 1
	fi

	PREFIX="level"
	LEVEL="$2"
	if [[ $2 == b* ]]; then
		LEVEL=$(echo $2 | cut -c 2)
		PREFIX="bonus"
	fi

	sshpass -p $FLAG ssh $IP -p 4242 -l $PREFIX$LEVEL
	exit 0
fi

if [ $1 = "copy" ]; then
	if [ -z $2 ]; then
		echo "usage: $0 copy <level>" 1>&2
		exit 1
	fi

	if [ $2 = "all" ]; then
		for i in {0..9}; do
			get_binary $i
		done
		for i in {0..4}; do
			get_binary b$i
		done
		exit 0
	fi

	get_binary $2
	exit 0
fi

