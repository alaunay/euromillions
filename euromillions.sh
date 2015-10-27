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
	echo "2 étoiles:"
	echo -n "$[ ( $RANDOM % 11 + 1 ) ] "
	echo "$[ ( $RANDOM % 11 + 1 ) ] "
}

# Start functions
numbers
stars
