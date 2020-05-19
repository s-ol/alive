#!/bin/bash
PP="$1" # "D:/alive_pkg/dist/$1/lua/"
PR=${PP//\//\\\\}\\\\?

echo "replacing '$PP' / '$PR' with relative paths"

for script in "dist/$2/lua/bin/"*.bat; do
  echo "fixing '$script'..."
  head -n 2 "$script" > "$script.nu"
  cat <<EOF >> "$script.nu"
set PR=%~dp0..\\
set PP=%PR:\\=/%
EOF

  case "$(basename "$script" .bat)" in
    alv-fltk|alv-wx)
      tail -n 2 "$script" | \
      sed -r "s|${PR}|%PR%|g" | \
      sed -r "s|${PP}|%PP%|g" | \
      sed 's|"%PR%bin\\lua5.3.exe"|start "Lua" "%PR%bin\\wlua5.3.exe"|' \
      >> "$script.nu"
      ;;
    *)
      tail -n 2 "$script" | \
      sed -r "s|${PR}|%PR%|g" | \
      sed -r "s|${PP}|%PP%|g" \
      >> "$script.nu"
      ;;
  esac
  mv "$script.nu" "$script"
done
