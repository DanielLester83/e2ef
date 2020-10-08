#!/bin/bash
ip=`echo $PAM_RHOST | cut -d " " -f 1`
if [ -z $ip ]; then
	ip=$(hostname -I)
fi
logger $PAM_USER login from $ip
for fname in /sys/devices/virtual/dmi/id/*;
do
  text="$(cat $fname 2>/dev/null)"
  if [[ -n "$text" && "$text" != "To be filled by O.E.M." && "$text" != "To Be Filled By O.E.M." ]]; then
      sy=$( echo -e "$sy\n$fname - $text\n\n")
  fi
done
if [ "$PAM_TYPE" = "open_session" ]; then
	echo -e "User $PAM_USER just logged on to $HOSTNAME from $ip\n\n---- HARDWARE INFO ----\n$sy" | mail -s "Login at $(date)" root
fi
if [ "$PAM_TYPE" = "close_session" ]; then
	echo -e "User $PAM_USER just logged off to $HOSTNAME from $ip\n\n---- HARDWARE INFO ----\n$sy" | mail -s "Logout at $(date)" root
fi
