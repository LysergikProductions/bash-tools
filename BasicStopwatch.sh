# some stuff before main function
INIT(){
  starting="MAIN loop starting"; ending="MAIN loop success"
  runMAIN=1; stopTime=0
  clear
}; INIT

# exit script when MAIN is done, if ever (in this case counting out 4 seconds)
exitScript(){
	tput cnorm
  trap - SIGINT SIGTERM SIGTERM # clear the trap
	kill -- -$$ # Send SIGTERM to child/sub processes
	exit
}; trap exitScript SIGINT SIGTERM # set trap

printf "Stop the time with any key!\n\n"

MAIN(){
  #printf "\n\n$starting\n"
  sleep 0.02
  
  printf "\r%*s" $((0)) "${stopTime}s"
 stopTime=$(awk "BEGIN {print ($stopTime+0.02)}")
}

# main loop running in subshell due to the '&'' after 'done'
tput civis
{ while ((runMAIN)); do
  if ! MAIN; then echo; runMain=0; fi
done; } &

# --------------------------------------------------
tput smso; tput rmso
oldstty=`stty -g`
stty -icanon -echo min 1 time 0
dd bs=1 count=1 >/dev/null 2>&1
stty "$oldstty"
# --------------------------------------------------

# everything after this point will occur after user inputs any key or if main loop exits
printf "\n\nYou pressed a key!\n\nGoodbye!\n"