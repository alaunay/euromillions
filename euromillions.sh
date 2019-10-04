#! /bin/bash

COUNTNUMBERS=5
NUMBERSUP=50
NUMBERSDOWN=1
COUNTSTARS=2
STARSUP=12
STARSDOWN=1

declare -a numbers_sorted
declare -a stars_sorted

# Get and print numbers
getnumbers () {

	mapfile -t numbers_sorted < <( shuf --random-source=/dev/random -i ${NUMBERSDOWN}-${NUMBERSUP} -n ${COUNTNUMBERS} | sort -n )

	# Print results
	echo "Numbers: ${numbers_sorted[*]}"

}

# Get and print stars
getstars () {

	mapfile -t stars_sorted < <(shuf --random-source=/dev/random -i ${STARSDOWN}-${STARSUP} -n ${COUNTSTARS} | sort -n )

	# Print results
	echo "Stars: ${stars_sorted[*]}"
}

# Start functions
getnumbers
getstars
