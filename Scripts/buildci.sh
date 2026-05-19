#!/bin/sh

base="${1##*/}"
base="${base%.*}"
cache="-fmodules-cache-path=$2"
compiled_macOS="$2/$base-macosx.air"
linked_macOS="$2/$base-macosx.metallib"
output="$2/${base}Data.tmp"
final="$2/${base}Data.swift"

source_path="$1"
xcrun -sdk macosx metal -fcikernel "$source_path" -c -o "$compiled_macOS" "$cache" || exit $?
xcrun -sdk macosx metallib -cikernel -o "$linked_macOS" "$compiled_macOS" || exit $?

echo "import Foundation" > "$output"
echo "#if os(macOS) || targetEnvironment(macCatalyst)" >> "$output"
echo "let ${base}Data = Data([" >> "$output"
xxd -i "$linked_macOS" | grep -E '^[[:space:][:digit:]a-fx,]*$' >> "$output"
echo "])" >> "$output"
echo "#else" >> "$output"
echo '#error("Unsupported platform")' >> "$output"
echo "#endif" >> "$output"

if [ -f "$final" ] && diff -q "$output" "$final" > /dev/null; then
    echo Output unchanged
    rm "$output"
else
    echo Output changed
    mv -f "$output" "$final"
fi
