#!/bin/sh

###
[ -z "$OPTLOCAL_SH" ] && {
readonly OPTLOCAL_SH='optlocal.sh'
###


. /opt/local/lib/common.sh


path_is_absolute () {
  local FUN_NAME='path_is_absolute'
  local FUN_ARG_NUM=1
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  CUR_PATH="$1"

  check_not_empty_arguments "$CUR_PATH" \
    || exit $EXIT_FAILURE

  printf "${CUR_PATH}\n" | grep -q '^/'

  if [ "$?" -eq "$SUCCESS" ] ; then
    return $SUCCESS
  else
    return $FAILURE
  fi
}


optlocal_paths () {
  local FUN_NAME='optlocal_paths'
  local FUN_ARG_NUM='2'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local ORIG_FILE="$1"
  local DEST_BASE="$2"

  check_not_empty_arguments "$ORIG_FILE" "$DEST_BASE" \
    || exit $EXIT_FAILURE

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
  local FUN_ARG_NUM='4'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local COMMAND_TYPE="$1"
  local ORIG_FILE="$2"
  local DEST_BASE="$3"
  local CONFIG_NAME="$4"
  local DEST_FILE=''
  local DEST_PATH=''

  check_not_empty_arguments "$COMMAND_TYPE" "$ORIG_FILE" \
      "$DEST_BASE" \
    || exit $EXIT_FAILURE

  local RESULT=`optlocal_paths $ORIG_FILE $DEST_BASE`
  ORIG_FILE="${RESULT%%;*}"
  DEST_FILE="${RESULT##*;}"
  unset RESULT

  if [ -n "$CONFIG_NAME" ] ; then
    local ORIG_HOST_FILE="${OPTHOSTS}/${CONFIG_NAME}/${ORIG_FILE##${OPTLOCAL}/}"

    if [ -f "$ORIG_HOST_FILE" ] ; then
      ORIG_FILE="$ORIG_HOST_FILE"
    fi
  fi

  printf ':: %s\n' "$ORIG_FILE ; $DEST_FILE"
  return 0

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
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_at_least "$FUN_ARG_NUM" "$#" \
    || {
      info_message 'syntax: optlocal {command} [a b c...] [dest=path] [conf=name]'
      exit $EXIT_FAILURE
    }

  local ORIG_FILES=''
  local DEST_BASE=''
  local CONFIG_NAME=''

  local COMMAND="$1"
  shift 1

  local CUR_ARG=''
  while [ "$#" -gt 0 ] ; do
    CUR_ARG="$1"
    shift 1

    case "${CUR_ARG%%=*}" in
      dest)
        DEST_BASE="${CUR_ARG#dest=}"
      ;;
      conf)
        CONFIG_NAME="${CUR_ARG#conf=}"
      ;;
      *)
        ORIG_FILES="${ORIG_FILES:+${ORIG_FILES} }${CUR_ARG}"
      ;;
    esac
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

  if [ "$?" -eq "$SUCCESS" ] ; then
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

  if [ "$?" -eq "$SUCCESS" ] ; then
    return $FAILURE
  fi

  local CUR_PATH=''
  local ORIG_FILE=''
  for ORIG_FILE in $ORIG_FILES ; do
    if [ -n "$CONFIG_NAME" ] ; then
      CUR_PATH="${OPTHOSTS}/${CONFIG_NAME}/${ORIG_FILE}"
      if [ -d "$CUR_PATH" ] ; then
        find "$CUR_PATH" \! -type d
      fi
    fi
  done
  unset ORIG_FILE


  local ORIG_FILE=''
  for ORIG_FILE in $ORIG_FILES ; do
    optlocal_exec "$COMMAND" "$ORIG_FILE" "$DEST_BASE" "$CONFIG_NAME"
  done
  unset ORIG_FILE

  return $SUCCESS
}


###
debug_message "$OPTLOCAL_SH included"
} || true
###

