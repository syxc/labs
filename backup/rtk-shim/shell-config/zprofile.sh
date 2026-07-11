# ~/.zprofile (源 108-117): 末尾去重再前置，确保 rtk-shim 居 PATH 首位
if [ "$CLAUDECODE" = "1" ]; then
  PATH=$(echo "$PATH" | sed "s|$HOME/.newmax/rtk-shim:||g")
  export PATH="$HOME/.newmax/rtk-shim:$PATH"
fi
