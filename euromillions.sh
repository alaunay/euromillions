#! /bin/sh

# Get and print numbers
numbers () {
	echo "5 numéros:"
	echo -n "$[ ( $RANDOM % 50 + 1 ) ] "
	echo -n "$[ ( $RANDOM % 50 + 1 ) ] "
	echo -n "$[ ( $RANDOM % 50 + 1 ) ] "
	echo -n "$[ ( $RANDOM % 50 + 1 ) ] "
	echo "$[ ( $RANDOM % 50 + 1 ) ] "
}

# Get and print stars
stars () {
	# initialize identical stars
	stars[0]=$[ ( $RANDOM % 12 + 1 ) ]
	stars[1]=${stars[0]}

	# loop until stars are different
	while [ ${stars[0]} = ${stars[1]} ]; do
		stars[1]="$[ ( $RANDOM % 12 + 1 ) ] "
	done

	# Sort stars
	IFS=$'\n' stars_sorted=($(sort -n <<<"${stars[*]}"))

	# Print results
	echo "Stars: ${stars_sorted[@]}"
}

# Start functions
numbers
stars
