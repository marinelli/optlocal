
###################################
if [ ! -z "$KSH_VERSION" ] ; then #
###################################


_NEW_PS1=''
_NEW_PS1=${_NEW_PS1}'$( printf \\001\\r\\001\\e[$((LINES-1))B\\001 )'
_NEW_PS1=${_NEW_PS1}${USER:+$USER}${HOSTNAME:+@$HOSTNAME}:
_NEW_PS1=${_NEW_PS1}'$( if [[ "$PWD" == "$HOME" ]] ; then printf "~" ; else printf "$PWD" ; fi )'
_NEW_PS1=${_NEW_PS1}$( if [[ "$( id -u )" -eq 0 ]] ; then printf ' # ' ; else printf ' $ ' ; fi )

export PS1=${_NEW_PS1}

unset _NEW_PS1


####
fi #
####

