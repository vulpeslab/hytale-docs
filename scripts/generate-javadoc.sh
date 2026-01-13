#!/bin/bash
# Generate JavaDoc API documentation from decompiled Hytale server source
# Requires: doxygen (brew install doxygen)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DECOMPILED_DIR="$PROJECT_ROOT/decompiled/com/hypixel/hytale"
OUTPUT_DIR="$PROJECT_ROOT/public/javadoc"

# Check for doxygen
if ! command -v doxygen &> /dev/null; then
    echo "Error: doxygen is not installed"
    echo "Install with: brew install doxygen"
    exit 1
fi

# Check for decompiled source
if [ ! -d "$DECOMPILED_DIR" ]; then
    echo "Error: Decompiled source not found at $DECOMPILED_DIR"
    echo "Please decompile HytaleServer.jar first"
    exit 1
fi

# Clean and create output directory
echo "Cleaning output directory..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Create Doxyfile configuration
DOXYFILE=$(mktemp)
cat > "$DOXYFILE" << EOF
PROJECT_NAME           = "Hytale Server API"
PROJECT_BRIEF          = "Hytale Server Documentation"
OUTPUT_DIRECTORY       = "$OUTPUT_DIR"
INPUT                  = "$DECOMPILED_DIR"
RECURSIVE              = YES
FILE_PATTERNS          = *.java
EXTENSION_MAPPING      = java=Java
EXTRACT_ALL            = YES
EXTRACT_PRIVATE        = YES
EXTRACT_STATIC         = YES
JAVADOC_AUTOBRIEF      = YES
GENERATE_HTML          = YES
GENERATE_LATEX         = NO
HTML_OUTPUT            = .
HTML_DYNAMIC_SECTIONS  = YES
SEARCHENGINE           = YES
SERVER_BASED_SEARCH    = NO
DISABLE_INDEX          = NO
GENERATE_TREEVIEW      = YES
TREEVIEW_WIDTH         = 250
SHOW_NAMESPACES        = YES
SHOW_FILES             = YES
WARNINGS               = NO
WARN_IF_UNDOCUMENTED   = NO
WARN_IF_DOC_ERROR      = NO
WARN_NO_PARAMDOC       = NO
QUIET                  = YES
EOF

# Generate documentation
echo "Generating JavaDoc documentation..."
echo "Source: $DECOMPILED_DIR"
echo "Output: $OUTPUT_DIR"
doxygen "$DOXYFILE"

# Cleanup
rm -f "$DOXYFILE"

# Report results
FILE_COUNT=$(find "$OUTPUT_DIR" -type f | wc -l | tr -d ' ')
echo "Done! Generated $FILE_COUNT files"
echo "JavaDocs available at: $OUTPUT_DIR"
