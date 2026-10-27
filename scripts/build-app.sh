#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Do not replace an executable while its process is still using the old TCC identity.
if /usr/bin/pgrep -x EisuMapping >/dev/null 2>&1; then
    printf '请先从菜单栏退出 EisuMapping，再重新构建。\n' >&2
    exit 1
fi

signing_identity="${SIGNING_IDENTITY:-}"
if [ -z "$signing_identity" ]; then
    identities=()
    while IFS= read -r identity; do
        [ -n "$identity" ] && identities+=("$identity")
    done < <(/usr/bin/security find-identity -v -p codesigning | /usr/bin/sed -nE \
        '/"(Apple Development:|Developer ID Application:|Mac Developer:)/s/^[[:space:]]*[0-9]+\) ([0-9A-F]{40}).*/\1/p')
    if [ "${#identities[@]}" -eq 1 ]; then
        signing_identity="${identities[0]}"
    elif [ "${#identities[@]}" -gt 1 ]; then
        printf '发现多个开发者证书，请通过 SIGNING_IDENTITY 指定一个，后续构建保持使用同一证书。\n' >&2
        exit 1
    else
        signing_identity='-'
    fi
fi

swift build --configuration release --arch arm64 --arch x86_64
binary_dir="$(swift build --configuration release --arch arm64 --arch x86_64 --show-bin-path)"
app_path="$PWD/build/EisuMapping.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp Resources/Info.plist "$app_path/Contents/Info.plist"
cp Resources/AppIcon.icns "$app_path/Contents/Resources/AppIcon.icns"
cp "$binary_dir/EisuMapping" "$app_path/Contents/MacOS/EisuMapping"
/usr/bin/codesign --force --options runtime --timestamp=none --sign "$signing_identity" "$app_path"
/usr/bin/codesign --verify --strict "$app_path"
touch "$app_path"
printf '\n应用已生成：%s\n' "$app_path"
if [ "$signing_identity" = '-' ]; then
    printf '当前使用临时签名：每次重新构建后，可能需要移除旧辅助功能条目并重新添加应用。\n'
else
    printf '已使用开发者证书签名；保持同一证书与应用位置，可在后续重建时沿用授权。\n'
fi
