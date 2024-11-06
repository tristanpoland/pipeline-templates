#!/bin/bash



set -euo pipefail

# Default CI directory name
DEFAULT_CI_DIR="ci"

# Array of directories to update (relative to CI directory)
DIRS_TO_UPDATE=(
    "pipeline"
    "scripts"
    "tasks"
)

# Array of files to copy from base template directory (relative to CI directory)
FILES_TO_COPY=(
    "repipe"
)

# Patterns of directories and files to preserve (not to be deleted or overwritten during update)
PRESERVE_PATTERNS=(
    "pipeline/custom-*"
    "pipeline/*custom*"
    "scripts/*"
    "tasks/*"
)

# Name of the template reference file
TEMPLATE_REF_FILE="template-ref"

# Function to display usage information
usage() {
    echo "Usage: $0 <template_path> <target_path> [ci_directory_name]"
    echo "  template_path: Path to the template CI directory"
    echo "  target_path: Path to the target project directory"
    echo "  ci_directory_name: Name of the CI directory (default: 'ci')"
    exit 1
}

# Check arguments
if [ "$#" -lt 2 ]; then
    usage
fi

TEMPLATE_PATH="$1"
TARGET_PATH="$2"
CI_DIR="${3:-$DEFAULT_CI_DIR}"

TEMPLATE_CI_PATH="$TEMPLATE_PATH/$CI_DIR"
TARGET_CI_PATH="$TARGET_PATH/$CI_DIR"

# Check if template CI directory exists
if [ ! -d "$TEMPLATE_CI_PATH" ]; then
    echo "Error: Template CI directory not found at $TEMPLATE_CI_PATH"
    exit 1
fi

# Create target CI directory if it doesn't exist
mkdir -p "$TARGET_CI_PATH"

# Function to safely remove directory contents
safe_remove_contents() {
    local dir="$1"
    local exclude_pattern=""
    for pattern in "${PRESERVE_PATTERNS[@]}"; do
        exclude_pattern="$exclude_pattern ! -path '*/$pattern'"
    done
    find "$dir" -mindepth 1 $exclude_pattern -delete
}

# Function to safely copy files, skipping preserved files
safe_copy() {
    local src="$1"
    local dest="$2"
    rsync -a --exclude-from=<(printf "%s\n" "${PRESERVE_PATTERNS[@]}") "$src" "$dest"
}

# Update specified directories
for dir in "${DIRS_TO_UPDATE[@]}"; do
    echo "Updating $dir directory..."
    target_dir="$TARGET_CI_PATH/$dir"
    mkdir -p "$target_dir"
    safe_remove_contents "$target_dir"
    safe_copy "$TEMPLATE_CI_PATH/$dir/" "$target_dir/"
done

# Copy specified files from base template to target
echo "Copying base template files..."
for file in "${FILES_TO_COPY[@]}"; do
    if [ -f "$TEMPLATE_CI_PATH/$file" ]; then
        should_copy=true
        for pattern in "${PRESERVE_PATTERNS[@]}"; do
            if [[ "$file" == $pattern ]]; then
                should_copy=false
                break
            fi
        done
        if $should_copy; then
            cp "$TEMPLATE_CI_PATH/$file" "$TARGET_CI_PATH/"
        else
            echo "Skipping preserved file: $file"
        fi
    fi
done

# Create template reference file
echo "Creating template reference file..."
template_hash=$(find "$TEMPLATE_CI_PATH" -type f ! -path "*/.git/*" -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)
echo "$template_hash" > "$TARGET_CI_PATH/$TEMPLATE_REF_FILE"

echo "CI update completed successfully."

# Function to compare directories and list potentially removed files
compare_directories() {
    local template_dir="$1"
    local target_dir="$2"
    local prefix="$3"

    find "$target_dir" -type f | while read -r target_file; do
        local rel_path="${target_file#$target_dir/}"
        local template_file="$template_dir/$rel_path"
        if [ ! -e "$template_file" ]; then
            echo "Potentially removed from template: $prefix$rel_path"
        fi
    done
}

echo "Identifying potentially removed files..."
compare_directories "$TEMPLATE_CI_PATH" "$TARGET_CI_PATH" "$CI_DIR/"
for dir in "${DIRS_TO_UPDATE[@]}"; do
    compare_directories "$TEMPLATE_CI_PATH/$dir" "$TARGET_CI_PATH/$dir" "$CI_DIR/$dir/"
done

# Check if template has changed
if [ -f "$TARGET_CI_PATH/$TEMPLATE_REF_FILE.old" ]; then
    old_hash=$(cat "$TARGET_CI_PATH/$TEMPLATE_REF_FILE.old")
    if [ "$old_hash" != "$template_hash" ]; then
        echo "Template has changed. New hash: $template_hash"
        echo "Old hash: $old_hash"
        echo "You may want to review changes and clean up any obsolete files."
    else
        echo "Template has not changed since last update."
    fi
fi

# Update the old reference file
mv "$TARGET_CI_PATH/$TEMPLATE_REF_FILE" "$TARGET_CI_PATH/$TEMPLATE_REF_FILE.old"

echo "CI update process completed."
