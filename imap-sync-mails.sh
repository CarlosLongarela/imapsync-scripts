#!/bin/sh
#
# $Id: sync_loop_unix.sh,v 1.13 2022/01/09 09:53:47 gilles Exp gilles $

# Example for imapsync massive migration on Unix systems.
# See also http://imapsync.lamiral.info/FAQ.d/FAQ.Massive.txt
#
# Data is supposed to be in imap-mails.txt in the following format:
# host001_1;user001_1;password001_1;host001_2;user001_2;password001_2;;
# ...
# The separator is the character semi-colon ";"
# this separator character can be changed to any character
# by changing IFS=';' in the while loop below.
#
# Each line contains 7 columns. These columns are the 6 parameter values
# for the imapsync command options
# --host1 --user1 --password1 --host2 --user2 --password2
# plus an extra column for extra parameters and a trailing fake column
# to avoid CR LF part going in the 7th parameter extra.
# So don't forget the last semicolon, especially on MacOS systems.
#
# You can also add extra options in this script after the variable "$@"
# Those options will be applied in every imapsync run, for every line.

# The imapsync command below is written in two lines to avoid a long line.
# The character backslash \ at the end of the first line is means
# "the command continues on the next line".
#
# Use character backslash \ at the end of each supplementary line,
# except for the last line.
#

# You can also pass extra options via the parameters of this script since
# they will be in "$@". Shell knowledge is your friend.

# The credentials filename "imap-mails.txt" used for the loop can be renamed
# by changing "imap-mails.txt" below.

# The file mail_sync_errors.txt will contain the lines from imap-mails.txt that ended
# up in error, for whatever reason. It's there to notice and replay easily
# the failed imapsync runs. Is is emptied at the beginning of the loop run.
# I let you junggle with it.

# Cloned by original file https://imapsync.lamiral.info/examples/sync_loop_unix.sh

if [ -z "$1" ]; then
    # read script parameter file text
    read -p "Enter the file name with mails: " file_name
else
    file_name=$1
fi

echo "The file name is: $file_name"

# Check if the file exists
if [ ! -f $file_name ]; then
    echo "File not found!"
    exit 1
fi

echo Looping on accounts credentials found in imap-mails.txt
echo
line_counter=0
# Empty the error listing
> mail_sync_errors.txt
{ while IFS=';' read  h1 u1 p1 h2 u2 p2 extra fake
    do
        line_counter=`expr 1 + $line_counter`
        { echo "$h1" | tr -d '\r' | egrep '^#|^ *$' ; } > /dev/null && continue # this skip commented lines in imap-mails.txt
        echo "==== Starting imapsync with --host1 $h1 --user1 $u1 --host2 $h2 --user2 $u2 $extra ===="
        if imapsync --host1 "$h1" --user1 "$u1" --password1 "$p1" \
                    --host2 "$h2" --user2 "$u2" --password2 "$p2" $extra
        then
                echo "Success sync for line $line_counter "
        else
                echo "$h1;$u1;$p1;$h2;$u2;$p2;$extra;" | tee -a mail_sync_errors.txt
        fi
        echo "==== Ended imapsync with --host1 $h1 --user1 $u1 --host2 $h2 --user2 $u2 $extra ===="
        echo
    done
} < $file_name
