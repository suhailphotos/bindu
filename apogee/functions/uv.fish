# Ensure tool bin exists
if set -q UV_TOOL_BIN_DIR
  mkdir -p $UV_TOOL_BIN_DIR 2>/dev/null
end

function uvp
  if set -q UV_PROJECT_ENVIRONMENT
    echo $UV_PROJECT_ENVIRONMENT
  else
    echo "(unset)"
  end
end
