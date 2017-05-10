#!/bin/sh

###
[ -z "$OPTLOCAL_SH" ] && {
readonly OPTLOCAL_SH='included'
###


. /opt/local/lib/common.sh


optlocal_paths () {
  local FUN_NAME='optlocal_paths'
  local FUN_ARG_NUM='2'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local ORIG_FILE="$1"
  local DEST_BASE="$2"

  check_not_empty_arguments "$FUN_NAME" "$ORIG_FILE" || \
    return $FAILURE

  local CHECK_RELATIVE_PATH=`printf $ORIG_FILE | sed -n "\:^/:p"`
  if [ -z "$CHECK_RELATIVE_PATH" ] ; then
    ORIG_FILE="${OPTLOCAL}/${ORIG_FILE}"
  else
    local CHECK_OPTLOCAL=`printf $ORIG_FILE | sed -n "\:^\${OPTLOCAL%%/}/:p"`
    if [ -z "$CHECK_OPTLOCAL" ] ; then
      return $FAILURE
    fi
  fi

  local SUFFIX_PATH=`printf "$ORIG_FILE" | sed "s:^\${OPTLOCAL%%/}/::"`

  [ "$DEST_BASE" == '/' ] && DEST_BASE=''

  printf "${ORIG_FILE};${DEST_BASE}/${SUFFIX_PATH}"

  return $SUCCESS
}


optlocal_exec () {
  local FUN_NAME='optlocal_exec'
  local FUN_ARG_NUM='3'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local COMMAND_TYPE="$1"
  local ORIG_FILE="$2"
  local DEST_BASE="$3"
  local DEST_FILE=''
  local DEST_PATH=''

  check_not_empty_arguments "$COMMAND_TYPE" "$ORIG_FILE" ||
    exit $EXIT_FAILURE

  local RESULT=`optlocal_paths $ORIG_FILE $DEST_BASE`
  ORIG_FILE="${RESULT%%;*}"
  DEST_FILE="${RESULT##*;}"
  unset RESULT

  [ ! -f "$ORIG_FILE" ] && return $FAILURE

  DEST_PATH=`dirname "$DEST_FILE"`

  case "$COMMAND_TYPE" in
  link|copy|replace)
    [ ! -d "$DEST_PATH" ] && {
      mkdir -p "$DEST_PATH"
      if [ "$?" -eq 0 ] ; then
        printf '>> %s\n' "$DEST_PATH created"
      else
        return $FAILURE
      fi
    }
    ;;
  *)
    exit $EXIT_FAILURE
    ;;
  esac

  local RESULT='0'
  local WELL_DONE=''

  case "$COMMAND_TYPE" in
  link)
    if [ -f "$DEST_FILE" ] ; then
      [ "$ORIG_FILE" != "`readlink $DEST_FILE`" ] && {
        rm -f "$DEST_FILE" && \
        ln -s "$ORIG_FILE" "$DEST_FILE" && \
          WELL_DONE='yes'
      }
    else
      ln -s "$ORIG_FILE" "$DEST_FILE" && \
        WELL_DONE='yes'
    fi
    RESULT="$?"
    ;;
  copy)
    if [ -f "$DEST_FILE" ] ; then
      cmp -s "$ORIG_FILE" "$DEST_FILE" || {
        mv -f "$DEST_FILE" "$DEST_FILE-orig" && \
        cp -a "$ORIG_FILE" "$DEST_FILE" && \
          WELL_DONE='yes'
      }
    else
      cp -a "$ORIG_FILE" "$DEST_FILE" && \
        WELL_DONE='yes'
    fi
    RESULT="$?"
    ;;
  replace)
    if [ -f "$DEST_FILE" ] ; then
      cmp -s "$ORIG_FILE" "$DEST_FILE" || {
        rm -f "$DEST_FILE" && \
        cp -a "$ORIG_FILE" "$DEST_FILE" && \
          WELL_DONE='yes'
      }
    else
      cp -a "$ORIG_FILE" "$DEST_FILE" && \
        WELL_DONE='yes'
    fi
    RESULT="$?"
    ;;
  *)
    return $FAILURE
    ;;
  esac

  if [[ "$RESULT" -eq 0 && -n "$WELL_DONE" ]] ; then
    printf ">> $COMMAND_TYPE : $ORIG_FILE -> $DEST_FILE\n"
  fi

  if [ "$RESULT" -ne 0 ] ; then
    return $FAILURE
  fi

  return $SUCCES
}


optlocal () {
  local FUN_NAME='optlocal'
  local FUN_ARG_NUM='1'

  check_num_arguments_at_least "$FUN_NAME" "$FUN_ARG_NUM" "$#" || {
    printf '!! %s : %s\n' "$FUN_NAME" 'syntax: optlocal {command} [a b c...] [dest=path]' 1>&2
    exit $EXIT_FAILURE
  }

  local ORIG_FILES=''
  local DEST_BASE=''

  local COMMAND="$1"
  shift 1

  local CUR_ARG=''
  while [ "$#" -gt 0 ] ; do
    CUR_ARG="$1"
    shift 1

    if [ "${CUR_ARG%%=*}" = 'dest' ] ; then
      DEST_BASE="${CUR_ARG#dest=}"
    else
      ORIG_FILES="${ORIG_FILES:+${ORIG_FILES} }${CUR_ARG}"
    fi
  done
  unset CUR_ARG

  if [ -z "$DEST_BASE" ] ; then
    DEST_BASE="${USRLOCAL%%/}"
  else
    DEST_BASE="${DEST_BASE%%/}"
  fi

  if [ -z "$DEST_BASE" ] ; then
    DEST_BASE='/'
  fi

  printf "${ORIG_FILES}\n" | grep -qE '^[[:blank:]]*$'

  if [ "$?" -eq 0 ] ; then
    local CUR_ARGS=''
    local CUR_LINE=''
    while read CUR_LINE ; do
      CUR_ARGS=`printf "$CUR_LINE" | sed -r 's/[[:blank:]]+/ /g' | sed -r 's/(^[[:blank:]]+|[[:blank:]]+$)//g'`
      ORIG_FILES="${ORIG_FILES:+${ORIG_FILES} }${CUR_ARGS}"
    done
    unset CUR_ARGS
    unset CUR_LINE
  fi

  printf "${ORIG_FILES}\n" | grep -qE '^[[:blank:]]*$'

  if [ "$?" -eq 0 ] ; then
    return $FAILURE
  fi

  local ORIG_FILE=''
  for ORIG_FILE in $ORIG_FILES ; do
    optlocal_exec "$COMMAND" "$ORIG_FILE" "$DEST_BASE"
  done
  unset ORIG_FILE

  return $SUCCESS
}


###
} # OPTLOCAL_SH
###

