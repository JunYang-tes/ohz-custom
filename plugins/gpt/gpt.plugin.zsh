function end_with() {
  local str=$1
  local suffix=$2
  if [[ "$str" == *"$suffix" ]]; then
    return 0
  else
    return 1
  fi
}
function start_with() {
  local str=$1
  local prefix=$2
  if [[ "$str" == "$prefix"* ]]; then
    return 0
  else
    return 1
  fi
}

function is_question() {
  local cmd=$1
  if start_with "$cmd" ","; then
    return 0
  else
    return 1
  fi
}

log_file=/tmp/gpt.log
function write_log() {
  local msg=$1
  echo -E $msg >> $log_file
}

function ask_gpt() {
  local p="I'll ask you a linux command or some questions. If I asked a linux command, you should only response a command without any explainations. The response format for command is \"cmd: <command content>\", the response format for others is \"exp: <content\". Now I am asking you: $*"
  local data=$(jq  -n --arg p "$p" '{"model": "gpt-3.5-turbo","messages": [{"role": "user", "content":$p}],"temperature": 0.7}')
  local resp=$(curl https://api.openai.com/v1/chat/completions -s \
   -H "Content-Type: application/json" \
   -H "Authorization: Bearer $OPEN_AI_KEY" \
   -d $data) #"{\"model\": \"gpt-3.5-turbo\",\"messages\": [{\"role\": \"user\", \"content\":$p}],\"temperature\": 0.7}")
  write_log "Request: $data"
  write_log "Response: $resp"
  echo -E $resp | jq '.choices[0].message.content' -r
}

function command_not_found_handler() {
  local cmd="$*"
  if is_question "$cmd"; then
  else
    echo "Unknown command: $cmd"
    return 127
  fi
}

function _preexec() {
  local cmd="$1"
  if is_question "$cmd"; then
    q=$cmd[2,-1]
    resp=$(ask_gpt "$q")

    if start_with $resp "cmd:"; then
      print -z $resp[5,-1]
    elif start_with "$resp" "exp:"; then
      local exp=$resp[5,-1]
      echo $exp
    else
      echo "Unknown response: $resp"
    fi
    return 1
  fi
}

bindkey -s '^t^u' ',翻译为英文:'
bindkey -s '^t^h' ',Translate to Chinese:'
bindkey "^x" backward-kill-line
add-zsh-hook preexec _preexec
