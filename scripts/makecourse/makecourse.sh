#!/bin/bash

# ============================================================ #
#  makecourse() - Scaffold a new uv-native course repository
# ============================================================ #

makecourse() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: makecourse <course-name>"
        return 1
    fi

    COURSE="$1"
    TEMPLATE_DIR="$HOME/.bashrc.d/bin/makecourse-tpl"

    echo ">>> Creating uv-native course project: $COURSE"

    # Directories
    mkdir -p "$COURSE"/{data,scripts,assignments,projects,docs,.devcontainer}

    # README
    if [[ ! -f "$COURSE/README.md" ]]; then
        sed "s/__COURSE_NAME__/$COURSE/g" \
            "$TEMPLATE_DIR/README.md.tpl" > "$COURSE/README.md"
        echo ">>> Created: $COURSE/README.md"
    else
        echo ">>> Skipping: $COURSE/README.md already exists."
    fi

    # pyproject.toml
    if [[ ! -f "$COURSE/pyproject.toml" ]]; then
        sed "s/__COURSE_NAME__/$COURSE/g" \
            "$TEMPLATE_DIR/pyproject.toml.tpl" > "$COURSE/pyproject.toml"
        echo ">>> Created: $COURSE/pyproject.toml"
    else
        echo ">>> Skipping: $COURSE/pyproject.toml already exists."
    fi

    # gitignore
    if [[ ! -f "$COURSE/.gitignore" ]]; then
        cp "$TEMPLATE_DIR/gitignore.tpl" "$COURSE/.gitignore"
        echo ">>> Created: $COURSE/.gitignore"
    else
        echo ">>> Skipping: $COURSE/.gitignore already exists."
    fi

    # Containerfile
    if [[ ! -f "$COURSE/Containerfile" ]]; then
        cp "$TEMPLATE_DIR/Containerfile.tpl" "$COURSE/Containerfile"
        echo ">>> Created: $COURSE/Containerfile"
    else
        echo ">>> Skipping: $COURSE/Containerfile already exists."
    fi

    # Devcontainer
    if [[ ! -f "$COURSE/.devcontainer/devcontainer.json" ]]; then
        sed "s/__COURSE_NAME__/$COURSE/g" \
            "$TEMPLATE_DIR/devcontainer.json.tpl" > "$COURSE/.devcontainer/devcontainer.json"
        echo ">>> Created: $COURSE/.devcontainer/devcontainer.json"
    else
        echo ">>> Skipping: $COURSE/.devcontainer/devcontainer.json already exists."
    fi

    # uv.lock placeholder
    if [[ ! -f "$COURSE/uv.lock" ]]; then
        touch "$COURSE/uv.lock"
        echo ">>> Created: $COURSE/uv.lock (placeholder)"
    else
        echo ">>> Skipping: $COURSE/uv.lock already exists."
    fi

    echo ">>> Done: $COURSE scaffold created."
}
