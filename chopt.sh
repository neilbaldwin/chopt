
#!/usr/bin/env bash

# CHOPT - Sample Chain Optimizer V1.0, Neil Baldwin 2025

#   Trims silence from between individual sounds in a sample chain
#   Reconstructs the chain inserting definable gap (to help with transient detecting in sampler)
#   Optionally normalise the volume of all individual sounds (volume set by option)
#   Outputs the processed chain as "<input_file>_CHOPT"

# Requirements: audio file processing uses Sound eXchange (SoX) so you'll need to install that somehow
# There's a good SoX guide here (not mine) including installation: https://hyaline.systems/blog/sox-guide/

# Check for installation of SoX before proceeding
if ! command -v sox > /dev/null; then
  echo
  echo "Error: SoX needs to be installed in order to use CHOPT."
  echo "Please see https://neilbaldwin/github.com/chopt/readme.md" for requirements/instructions.""
  echo
  exit 1
fi

set -euo pipefail

# Set defaults
input_file=" "
minimum_silence=0.05
threshold=0.5
gap_length=0.1
normalise=false

# Process options
while getopts "i:m:t:g:n:" opt; do
  case "${opt}" in
    i)
      input_file=$OPTARG
      ;;
    m)
      minimum_silence=$OPTARG
      ;;
    t)
      threshold=$OPTARG
      ;;
    g)
      gap_length=$OPTARG
      ;;
    n)
      normalise=$OPTARG
      ;;
  esac
done

# If no input file then show usage instructions
# NOTE: very, VERY crude checking of input file
if [ "$input_file" == " " ] || [ ! -f "$input_file" ]; then
  echo "Error: no input file specified or input file not found."
  echo "Usage: $0 -i <input_wav> [-m <minimum silence> -t <threshold> -g <gap length> -n <normalise peak>]"
  exit 1
fi

# --- Prepare output ---
input_dir="$(dirname "$input_file")"
basename="${input_file%.*}"
extension="${input_file##*.}"
output="$input_dir/${basename}_CHOPT.${extension}"

# Create a temporary folder for slices and trap to automatically remove
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Processing: '$input_file'"
echo "Silence threshold: ${threshold}%"
echo "Minimum silence length: ${minimum_silence}s"
echo "Gap length: ${gap_length}s"
echo "Normalising: $normalise"

# Split input file based on silence
sox "$input_file" "$tmpdir/slice.wav" \
    silence 1 "$minimum_silence" "${threshold}%" 1 "$minimum_silence" "${threshold}%" : newfile : restart

# Get all split files into list
slices=( "$tmpdir"/slice*.wav )

if [ ${#slices[@]} -eq 0 ]; then
    echo "No transients detected. Try lowering threshold or minimum silence duration."
    exit 1
fi

echo "Found ${#slices[@]} slices:"

# Optional normalisation
if [ $normalise != "false" ]; then
  for f in "${slices[@]}"; do
    # Make temporary output file then move output file to input file - SoX doesn't let you overwrite source files
    n_file="$(mktemp).wav"
    sox $f "$n_file" norm "$normalise"
    rm "$f"
    mv "$n_file" "$f"
  done
fi

# Read original audio format for output stage
rate=$(sox --i -r "$input_file")
channels=$(sox --i -c "$input_file")

# Generate fixed gap audio file
gapfile="$tmpdir/gap.wav"
sox -n -r "$rate" -c "$channels" "$gapfile" trim 0.0 "$gap_length"

# Build file list for joining
concat_files=()
for i in "${!slices[@]}"; do
    concat_files+=("${slices[i]}")
    # Add gap after each slice except the last
    if [ "$i" -lt $((${#slices[@]}-1)) ]; then
        concat_files+=("$gapfile")
    fi
done

# Join everything back together with SoX
sox "${concat_files[@]}" "$output"

echo "Done. Output saved as: $output"
