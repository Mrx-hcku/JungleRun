#!/usr/bin/env bash
# Extracts one or more .unitypackage files into Assets/, reconstructing the
# real folder paths and .meta files from the GUID-folder format Unity uses.
#
# A .unitypackage is just a gzipped tar. Inside, each entry lives in a
# folder named by its GUID, containing:
#   asset        -> the actual file content (only present for files, not folders)
#   asset.meta   -> the .meta file content
#   pathname     -> text file whose first line is the real "Assets/..." path
#
# Usage: ./extract_unitypackage.sh <path-to-folder-of-.unitypackage-files> <repo-root>
# Example: ./extract_unitypackage.sh RawPackages .

set -euo pipefail

PACKAGE_DIR="${1:-RawPackages}"
REPO_ROOT="${2:-.}"

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "No package directory at '$PACKAGE_DIR' — skipping extraction."
    exit 0
fi

shopt -s nullglob
packages=("$PACKAGE_DIR"/*.unitypackage)

if [ ${#packages[@]} -eq 0 ]; then
    echo "No .unitypackage files found in '$PACKAGE_DIR' — skipping extraction."
    exit 0
fi

for pkg in "${packages[@]}"; do
    echo "Extracting: $pkg"
    work_dir="$(mktemp -d)"
    tar -xzf "$pkg" -C "$work_dir"

    # Each top-level dir in the extracted tar is named by GUID
    for guid_dir in "$work_dir"/*/; do
        [ -d "$guid_dir" ] || continue
        pathname_file="${guid_dir}pathname"
        [ -f "$pathname_file" ] || continue

        rel_path="$(head -n 1 "$pathname_file" | tr -d '\r\n')"
        [ -n "$rel_path" ] || continue

        dest_path="$REPO_ROOT/$rel_path"
        dest_dir="$(dirname "$dest_path")"
        mkdir -p "$dest_dir"

        if [ -f "${guid_dir}asset" ]; then
            cp "${guid_dir}asset" "$dest_path"
            echo "  + $rel_path"
        else
            # Folder-only entry — just ensure the directory exists
            mkdir -p "$dest_path"
        fi

        if [ -f "${guid_dir}asset.meta" ]; then
            cp "${guid_dir}asset.meta" "${dest_path}.meta"
        fi
    done

    rm -rf "$work_dir"
    echo "Done: $pkg"
done

echo "All packages extracted into $REPO_ROOT"
