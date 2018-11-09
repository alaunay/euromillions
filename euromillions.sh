#! /bin/bash

NUMBERS=5
STARS=2
NUMBERSUP=50
NUMBERSDOWN=1
STARSUP=12
STARSDOWN=1

# Get and print numbers
numbers () {
	echo "${NUMBERS} numéros:"
	echo -n "$[ ( $RANDOM % ${NUMBERSUP} + ${NUMBERSDOWN} ) ] "
	echo -n "$[ ( $RANDOM % ${NUMBERSUP} + ${NUMBERSDOWN} ) ] "
	echo -n "$[ ( $RANDOM % ${NUMBERSUP} + ${NUMBERSDOWN} ) ] "
	echo -n "$[ ( $RANDOM % ${NUMBERSUP} + ${NUMBERSDOWN} ) ] "
	echo "$[ ( $RANDOM % ${NUMBERSUP} + ${NUMBERSDOWN} ) ] "
}

# Get and print stars
stars () {
	# initialize identical stars
	stars[0]=$[ ( $RANDOM % ${STARSUP} + ${STARSDOWN} ) ]
	stars[1]=${stars[0]}

	# loop until stars are different
	while [ ${stars[0]} = ${stars[1]} ]; do
		stars[1]="$[ ( $RANDOM % ${STARSUP} + ${STARSDOWN} ) ] "
	done

	# Sort stars
	IFS=$'\n' stars_sorted=($(sort -n <<<"${stars[*]}"))

	# Print results
	echo "Stars: ${stars_sorted[@]}"
}

# Start functions
numbers
stars
