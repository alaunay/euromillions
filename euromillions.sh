#! /bin/bash

COUNTNUMBERS=5
NUMBERSUP=50
NUMBERSDOWN=1
STARSUP=12
STARSDOWN=1

declare -a nums
declare -a stars

# Get and print numbers
getnumbers () {

	# Initialize array with random number
	nums[0]="$(( $RANDOM % ${NUMBERSUP} + ${NUMBERSDOWN} ))"

	local i=1
	while [ "x${i}" != "x${COUNTNUMBERS}" ]; do
		nums[${i}]="$(( $RANDOM % ${NUMBERSUP} + ${NUMBERSDOWN} ))"

		# Ensure uniqueness: loop to check if num[i-1] != num[i]
		let previous=i-1;
		while [ ${nums[$previous]} = ${nums[$i]} ]; do
			nums[${i}]="$(( $RANDOM % ${NUMBERSUP} + ${NUMBERSDOWN} ))"
		done
		let i=i+1;
	done

	# Sort numbers
	IFS=$'\n' numbers_sorted=($(sort -n <<<"${nums[*]}"))

	# Print results
	echo "Numbers: ${numbers_sorted[@]}"

}

# Get and print stars
getstars () {
	# initialize identical stars
	stars[0]=$[ ( $RANDOM % ${STARSUP} + ${STARSDOWN} ) ]
	stars[1]=${stars[0]}

	# loop until stars are different
	while [ "x${stars[0]}" = "x${stars[1]}" ]; do
		stars[1]="$[ ( $RANDOM % ${STARSUP} + ${STARSDOWN} ) ] "
	done

	# Sort stars
	IFS=$'\n' stars_sorted=($(sort -n <<<"${stars[*]}"))

	# Print results
	echo "Stars: ${stars_sorted[@]}"
}

# Start functions
getnumbers
getstars
