#!/bin/sh

base="${1##*/}"
base="${base%.*}"
source_dir="${1%/*}"
cache="-fmodules-cache-path=$2"
compiled_macOS="$2/$base-macosx.air"
linked_macOS="$2/$base-macosx.metallib"
output="$2/${base}Data.tmp"
final="$2/${base}Data.swift"

source_path="$1"

# Detect whether this is a SwiftUI entry point or a CI entry point.
if echo "$base" | grep -qE 'SwiftUIFilter$'; then
    # SwiftUI stitchable path: compile and link as a normal Metal library.
    xcrun -sdk macosx metal "$source_path" -I "$source_dir" -c -o "$compiled_macOS" "$cache" || exit $?
    xcrun -sdk macosx metallib -o "$linked_macOS" "$compiled_macOS" || exit $?
else
    # Core Image kernel path: compile and link with CI flags.
    xcrun -sdk macosx metal -fcikernel "$source_path" -I "$source_dir" -c -o "$compiled_macOS" "$cache" || exit $?
    xcrun -sdk macosx metallib -cikernel -o "$linked_macOS" "$compiled_macOS" || exit $?
fi

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
