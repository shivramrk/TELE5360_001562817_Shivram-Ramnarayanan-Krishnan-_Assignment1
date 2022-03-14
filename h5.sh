#!/bin/bash

echo $1 | grep -qE '^[0-9]{5}(-[0-9]{4})?$'

if [ $? -eq 0 ]; then
	echo "$1 is a US postal code."
else
	echo "$1 is a canadian postal code."
fi
