#!/usr/bin/env zsh
set -euo pipefail
setopt extended_glob

SCRIPT_DIR=${0:A:h}
TABLE_MD=${TOPDESK_SPECS_MD:-"$SCRIPT_DIR/topdesk-api-specs.md"}
PROJECT_DIR=${TOPDESK_MCP_DIR:-"/Users/lucianoguerche/Documents/GitHub/topdesk-mcp"}
SPEC_CACHE_DIR=${TOPDESK_SPEC_CACHE_DIR:-"/tmp/topdesk-mcp-specs"}
LANGUAGE=${MCPIFY_LANGUAGE:-"rust"}
DEFAULT_API_NAME="General API"
DEFAULT_API_VERSION="1.2.0"
DEFAULT_LABEL="general-1.2.0"
FORCE="${TOPDESK_FORCE:-0}"

while (( $# > 0 )); do
  case "$1" in
    --force|-f)
      FORCE="1"
      shift
      ;;
    --help|-h)
      print "Usage: $0 [--force]"
      print ""
      print "Environment overrides:"
      print "  TOPDESK_SPECS_MD       Path to topdesk-api-specs.md"
      print "  TOPDESK_MCP_DIR        Output project directory"
      print "  TOPDESK_SPEC_CACHE_DIR Downloaded/normalized spec cache directory"
      print "  MCPIFY_LANGUAGE        mcpify output language, default: rust"
      print "  TOPDESK_FORCE=1        Same as --force"
      exit 0
      ;;
    *)
      print -u2 "Unknown argument: $1"
      print -u2 "Usage: $0 [--force]"
      exit 1
      ;;
  esac
done

if [[ ! -f "$TABLE_MD" ]]; then
  print -u2 "Spec table not found: $TABLE_MD"
  exit 1
fi

if [[ -d "$PROJECT_DIR" && -n "$(ls -A "$PROJECT_DIR" 2>/dev/null)" && "$FORCE" != "1" ]]; then
  print -u2 "Target directory already exists and is not empty: $PROJECT_DIR"
  print -u2 "Run with --force, or export TOPDESK_FORCE=1, to pass --force to mcpify generation."
  exit 1
fi

for dependency in curl node mcpify; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    print -u2 "Required command not found: $dependency"
    exit 1
  fi
done

slugify() {
  local value="$1"
  value="${value:l}"
  value="${value//&/ and }"
  value="${value//[^a-z0-9]##/-}"
  value="${value##-}"
  value="${value%%-}"
  print -r -- "$value"
}

version_slugify() {
  local value="$1"
  value="${value:l}"
  value="${value//&/ and }"
  value="${value//[^a-z0-9.]##/-}"
  value="${value##-}"
  value="${value%%-}"
  print -r -- "$value"
}

api_slug_from_url() {
  local url="$1"
  local file="${url:t}"
  local stem="${file:r}"

  if [[ "$stem" == *_specification_* ]]; then
    print -r -- "${stem%%_specification_*}"
  elif [[ "$stem" == *_* ]]; then
    print -r -- "${stem%%_*}"
  else
    slugify "$stem"
  fi
}

version_label() {
  local api_name="$1"
  local api_version="$2"
  local url="$3"
  local api_slug version_slug

  api_slug="$(api_slug_from_url "$url")"
  version_slug="$(version_slugify "$api_version")"

  if [[ -z "$api_slug" || -z "$version_slug" ]]; then
    print -u2 "Could not build version label for: $api_name / $api_version / $url"
    exit 1
  fi

  print -r -- "$api_slug-$version_slug"
}

normalize_spec() {
  local input_file="$1"
  local output_file="$2"

  node - "$input_file" "$output_file" <<'NODE'
const fs = require("node:fs");

const inputFile = process.argv[2];
const outputFile = process.argv[3];
const original = fs.readFileSync(inputFile, "utf8");

const basicAuthOpenApi3 = {
  type: "http",
  scheme: "basic",
  description: "TOPdesk API Basic Auth using the TOPdesk username and application token.",
};

const basicAuthSwagger2 = {
  type: "basic",
  description: "TOPdesk API Basic Auth using the TOPdesk username and application token.",
};

function normalizeJson(text) {
  const spec = JSON.parse(text);
  if (typeof spec.openapi === "string" && spec.openapi.startsWith("3.")) {
    spec.components ??= {};
    spec.components.securitySchemes ??= {};
    spec.components.securitySchemes.BasicAuth ??= basicAuthOpenApi3;
  } else {
    spec.securityDefinitions ??= {};
    spec.securityDefinitions.BasicAuth ??= basicAuthSwagger2;
  }
  if (!Array.isArray(spec.security) || spec.security.length === 0) {
    spec.security = [{ BasicAuth: [] }];
  }
  addMissingJsonParameterSchemas(spec);
  return `${JSON.stringify(spec, null, 2)}\n`;
}

function addMissingJsonParameterSchemas(spec) {
  for (const pathItem of Object.values(spec.paths ?? {})) {
    if (!pathItem || typeof pathItem !== "object") continue;
    for (const operation of Object.values(pathItem)) {
      if (!operation || typeof operation !== "object" || !Array.isArray(operation.parameters)) continue;
      for (const parameter of operation.parameters) {
        if (!parameter || typeof parameter !== "object" || "$ref" in parameter) continue;
        if (!["query", "path", "header", "cookie"].includes(parameter.in)) continue;
        if (parameter.schema == null && parameter.content == null) {
          parameter.schema = { type: "string" };
        }
      }
    }
  }
}

function countLeadingSpaces(line) {
  return line.match(/^\s*/)[0].length;
}

function hasTopLevelKey(lines, key) {
  const pattern = new RegExp(`^${key}:\\s*(?:$|#)`);
  return lines.some((line) => pattern.test(line));
}

function hasSecuritySchemes(lines) {
  return lines.some((line) => /^\s*securitySchemes\s*:/.test(line));
}

function hasBasicAuth(lines) {
  return lines.some((line) => /^\s*BasicAuth\s*:/.test(line));
}

function insertIntoExistingSecuritySchemes(lines) {
  const idx = lines.findIndex((line) => /^\s*securitySchemes\s*:/.test(line));
  if (idx < 0 || hasBasicAuth(lines)) return lines;

  const indent = countLeadingSpaces(lines[idx]);
  const childIndent = " ".repeat(indent + 2);
  const propIndent = " ".repeat(indent + 4);
  const block = [
    `${childIndent}BasicAuth:`,
    `${propIndent}type: http`,
    `${propIndent}scheme: basic`,
    `${propIndent}description: TOPdesk API Basic Auth using the TOPdesk username and application token.`,
  ];

  return [...lines.slice(0, idx + 1), ...block, ...lines.slice(idx + 1)];
}

function insertSecuritySchemesIntoComponents(lines) {
  const idx = lines.findIndex((line) => /^components\s*:/.test(line));
  if (idx < 0 || hasSecuritySchemes(lines)) return lines;

  const block = [
    "  securitySchemes:",
    "    BasicAuth:",
    "      type: http",
    "      scheme: basic",
    "      description: TOPdesk API Basic Auth using the TOPdesk username and application token.",
  ];

  return [...lines.slice(0, idx + 1), ...block, ...lines.slice(idx + 1)];
}

function appendComponentsWithSecuritySchemes(lines) {
  if (hasTopLevelKey(lines, "components")) return lines;

  return [
    ...lines,
    "components:",
    "  securitySchemes:",
    "    BasicAuth:",
    "      type: http",
    "      scheme: basic",
    "      description: TOPdesk API Basic Auth using the TOPdesk username and application token.",
  ];
}

function normalizeYaml(text) {
  let lines = text.replace(/\s+$/u, "").split(/\r?\n/);

  if (hasSecuritySchemes(lines)) {
    lines = insertIntoExistingSecuritySchemes(lines);
  } else if (hasTopLevelKey(lines, "components")) {
    lines = insertSecuritySchemesIntoComponents(lines);
  } else {
    lines = appendComponentsWithSecuritySchemes(lines);
  }

  if (!hasTopLevelKey(lines, "security")) {
    lines.push("security:", "  - BasicAuth: []");
  }

  lines = addMissingParameterSchemas(lines);

  return `${lines.join("\n")}\n`;
}

function parameterBlockNeedsSchema(block) {
  const joined = block.join("\n");
  return /\n\s+in:\s+(query|path|header|cookie)\b/.test(joined)
    && !/\n\s+schema:\s*/.test(joined)
    && !/\n\s+content:\s*/.test(joined);
}

function addMissingParameterSchemas(lines) {
  const patched = [];

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const nameMatch = line.match(/^(\s*)-\s+name:\s*/);

    if (!nameMatch) {
      patched.push(line);
      continue;
    }

    const itemIndent = nameMatch[1].length;
    const block = [line];
    let j = i + 1;

    for (; j < lines.length; j += 1) {
      const nextLine = lines[j];
      const nextIndent = countLeadingSpaces(nextLine);
      if (nextLine.trim() && nextIndent <= itemIndent) break;
      block.push(nextLine);
    }

    patched.push(...block);
    if (parameterBlockNeedsSchema(block)) {
      const propIndent = " ".repeat(itemIndent + 2);
      patched.push(`${propIndent}schema:`, `${propIndent}  type: string`);
    }

    i = j - 1;
  }

  return patched;
}

let normalized;
try {
  normalized = normalizeJson(original);
} catch {
  normalized = normalizeYaml(original);
}

fs.writeFileSync(outputFile, normalized);
NODE
}

download_and_normalize_spec() {
  local label="$1"
  local spec_url="$2"
  local extension="${spec_url:t:e}"
  local raw_file converted_file normalized_file source_file

  [[ -z "$extension" ]] && extension="yaml"

  mkdir -p "$SPEC_CACHE_DIR"
  raw_file="$SPEC_CACHE_DIR/${label}.raw.${extension}"
  converted_file="$SPEC_CACHE_DIR/${label}.openapi3.yaml"
  normalized_file="$SPEC_CACHE_DIR/${label}.normalized.${extension}"

  print "Downloading $label -> $raw_file" >&2
  curl -fsSL -A "Mozilla/5.0" "$spec_url" -o "$raw_file"

  source_file="$raw_file"
  if node - "$raw_file" <<'NODE'
const fs = require("node:fs");
const inputFile = process.argv[2];
const text = fs.readFileSync(inputFile, "utf8");

try {
  const parsed = JSON.parse(text);
  process.exit(parsed.swagger === "2.0" ? 0 : 1);
} catch {
  process.exit(/^\s*swagger\s*:\s*['"]?2\.0['"]?\s*$/m.test(text) ? 0 : 1);
}
NODE
  then
    if ! command -v swagger2openapi >/dev/null 2>&1; then
      print -u2 "Warning: $label is Swagger 2.0, but swagger2openapi is not installed."
      print -u2 "Install with: npm install -g swagger2openapi"
      return 1
    fi

    print "Converting Swagger 2.0 to OpenAPI 3.0 for $label -> $converted_file" >&2
    swagger2openapi \
      --patch \
      --warnOnly \
      --yaml \
      --targetVersion 3.0.3 \
      --outfile "$converted_file" \
      "$raw_file" >&2

    source_file="$converted_file"
    extension="yaml"
    normalized_file="$SPEC_CACHE_DIR/${label}.normalized.${extension}"
  fi

  print "Normalizing BasicAuth for $label -> $normalized_file" >&2
  normalize_spec "$source_file" "$normalized_file"

  print -r -- "$normalized_file"
}

typeset -a rows
typeset -a skipped_versions
while IFS=$'\t' read -r api_name api_version spec_url; do
  [[ -z "$api_name" || -z "$api_version" || -z "$spec_url" ]] && continue
  rows+=("${api_name}"$'\t'"${api_version}"$'\t'"${spec_url}")
done < <(
  awk -F'|' '
    /^## Failed\/Skipped Versions/ { exit }
    /^\|/ && $2 !~ /API Name/ && $2 !~ /^---/ {
      api=$2; version=$3; url=$4;
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", api);
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", version);
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", url);
      if (url ~ /^https?:\/\//) {
        print api "\t" version "\t" url;
      }
    }
  ' "$TABLE_MD"
)

if (( ${#rows[@]} == 0 )); then
  print -u2 "No spec rows found in: $TABLE_MD"
  exit 1
fi

default_spec_url=""
for row in "${rows[@]}"; do
  IFS=$'\t' read -r api_name api_version spec_url <<< "$row"
  if [[ "$api_name" == "$DEFAULT_API_NAME" && "$api_version" == "$DEFAULT_API_VERSION" ]]; then
    default_spec_url="$spec_url"
    break
  fi
done

if [[ -z "$default_spec_url" ]]; then
  print -u2 "Default spec not found: $DEFAULT_API_NAME $DEFAULT_API_VERSION"
  exit 1
fi

force_args=()
if [[ "$FORCE" == "1" ]]; then
  force_args=(--force)
fi

print "Generating TOPdesk MCP project in: $PROJECT_DIR"
print "Default OpenAPI spec: $DEFAULT_LABEL -> $default_spec_url"
default_spec_file="$(download_and_normalize_spec "$DEFAULT_LABEL" "$default_spec_url")"

mcpify \
  -i "$default_spec_file" \
  -o "$PROJECT_DIR" \
  --language "$LANGUAGE" \
  --api-version "$DEFAULT_LABEL" \
  "${force_args[@]}"

for row in "${rows[@]}"; do
  IFS=$'\t' read -r api_name api_version spec_url <<< "$row"
  label="$(version_label "$api_name" "$api_version" "$spec_url")"

  if [[ "$label" == "$DEFAULT_LABEL" ]]; then
    continue
  fi

  if ! spec_file="$(download_and_normalize_spec "$label" "$spec_url")"; then
    print -u2 "Warning: skipping $label because the spec could not be downloaded or normalized: $spec_url"
    skipped_versions+=("$label download-or-normalize-failed $spec_url")
    continue
  fi

  print "Adding $label -> $spec_file"
  if ! mcpify add-version \
    --project "$PROJECT_DIR" \
    --version "$label" \
    -i "$spec_file"; then
    print -u2 "Warning: skipping $label because mcpify could not ingest this spec: $spec_file"
    skipped_versions+=("$label mcpify-add-version-failed $spec_url")
    continue
  fi
done

if (( ${#skipped_versions[@]} > 0 )); then
  print ""
  print "Skipped ${#skipped_versions[@]} version(s):"
  for skipped in "${skipped_versions[@]}"; do
    print "  - $skipped"
  done
fi

print "Done. TOPdesk MCP project created at: $PROJECT_DIR"
