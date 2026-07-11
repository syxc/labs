# ~/.zshenv (源 369-382): CLAUDECODE=1 时前置 rtk-shim 到 PATH
if [ "$CLAUDECODE" = "1" ]; then
  case ":$PATH:" in
    *":$HOME/.newmax/rtk-shim:"*) ;;
    *) export PATH="$HOME/.newmax/rtk-shim:$PATH" ;;
  esac
fi
