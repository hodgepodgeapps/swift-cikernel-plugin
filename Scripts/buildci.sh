#!/bin/sh

base="${1##*/}"
base="${base%.*}"
cache="-fmodules-cache-path=$2"
active_sdk="${SWIFT_CIKERNEL_ACTIVE_SDK:-all}"
compiled_macOS="$2/$base-macosx.air"
linked_macOS="$2/$base-macosx.metallib"
compiled_iOS="$2/$base-iphoneos.air"
linked_iOS="$2/$base-iphoneos.metallib"
compiled_tvOS="$2/$base-tvos.air"
linked_tvOS="$2/$base-tvos.metallib"
compiled_visionOS="$2/$base-visionos.air"
linked_visionOS="$2/$base-visionos.metallib"
output="$2/${base}Data.tmp"
final="$2/${base}Data.swift"

xcrun_metal_compile() {
    xcrun -sdk "$1" metal -fcikernel "$2" -c -o "$3" "$4" || exit $?
}

xcrun_metal_link() {
    xcrun -sdk "$1" metallib -cikernel -o "$2" "$3" || exit $?
}

build_sdk() {
    case "$1" in
        macosx)
            xcrun_metal_compile macosx "$source_path" "$compiled_macOS" "$cache"
            xcrun_metal_link macosx "$linked_macOS" "$compiled_macOS"
            ;;
        iphoneos)
            xcrun_metal_compile iphoneos "$source_path" "$compiled_iOS" "$cache"
            xcrun_metal_link iphoneos "$linked_iOS" "$compiled_iOS"
            ;;
        appletvos)
            xcrun_metal_compile appletvos "$source_path" "$compiled_tvOS" "$cache"
            xcrun_metal_link appletvos "$linked_tvOS" "$compiled_tvOS"
            ;;
        xros)
            xcrun_metal_compile xros "$source_path" "$compiled_visionOS" "$cache"
            xcrun_metal_link xros "$linked_visionOS" "$compiled_visionOS"
            ;;
    esac
}

source_path="$1"

if [ "$active_sdk" = "all" ]; then
    for sdk in macosx iphoneos appletvos xros; do
        build_sdk "$sdk"
    done
else
    build_sdk "$active_sdk"
fi

echo "import Foundation" > "$output"

if [ "$active_sdk" = "all" ]; then
    echo "#if os(macOS) || targetEnvironment(macCatalyst)" >> "$output"
    echo "let ${base}Data = Data([" >> "$output"
    xxd -i "$linked_macOS" | grep -E '^[[:space:][:digit:]a-fx,]*$' >> "$output"
    echo "])" >> "$output"

    echo "#elseif os(iOS)" >> "$output"
    echo "let ${base}Data = Data([" >> "$output"
    xxd -i "$linked_iOS" | grep -E '^[[:space:][:digit:]a-fx,]*$' >> "$output"
    echo "])" >> "$output"

    echo "#elseif os(tvOS)" >> "$output"
    echo "let ${base}Data = Data([" >> "$output"
    xxd -i "$linked_tvOS" | grep -E '^[[:space:][:digit:]a-fx,]*$' >> "$output"
    echo "])" >> "$output"

    echo "#elseif os(visionOS)" >> "$output"
    echo "let ${base}Data = Data([" >> "$output"
    xxd -i "$linked_visionOS" | grep -E '^[[:space:][:digit:]a-fx,]*$' >> "$output"
    echo "])" >> "$output"
else
    case "$active_sdk" in
        macosx)
            echo "#if os(macOS) || targetEnvironment(macCatalyst)" >> "$output"
            selected_lib="$linked_macOS"
            ;;
        iphoneos)
            echo "#if os(iOS)" >> "$output"
            selected_lib="$linked_iOS"
            ;;
        appletvos)
            echo "#if os(tvOS)" >> "$output"
            selected_lib="$linked_tvOS"
            ;;
        xros)
            echo "#if os(visionOS)" >> "$output"
            selected_lib="$linked_visionOS"
            ;;
        *)
            echo '#error("Unsupported SWIFT_CIKERNEL_ACTIVE_SDK value")' >> "$output"
            selected_lib=""
            ;;
    esac

    if [ -n "$selected_lib" ]; then
        echo "let ${base}Data = Data([" >> "$output"
        xxd -i "$selected_lib" | grep -E '^[[:space:][:digit:]a-fx,]*$' >> "$output"
        echo "])" >> "$output"
    fi
fi

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
