#!/bin/bash
# datacollector.sh — Automated Dataset Collector & Summarizer
# ------------------------------------------------------------
# Downloads a dataset (ZIP or CSV), detects its delimiter automatically,
# identifies numerical columns, and produces a Markdown summary of basic stats.
# Demonstrates process control, file handling, text manipulation, and automation.

# Prompt user for dataset URL
read -p "Enter the URL to a CSV dataset (ZIP or CSV): " url

# Create and navigate into a temporary directory
mkdir -p dataset_temp
cd dataset_temp || exit

# Download the dataset using curl (follows redirects with -L)
curl -L "$url" -o data.zip

# Extract CSV if ZIP, or rename directly if raw CSV
if file data.zip | grep -q "Zip archive"; then
    unzip -q data.zip
    csv_file=$(find . -name "*.csv" | head -n 1)
else
    mv data.zip data.csv
    csv_file="data.csv"
fi

# Validate that a CSV file exists
if [ ! -f "$csv_file" ]; then
    echo "No CSV file found. Exiting."
    exit 1
fi

# ------------------------------------------------------------
# DELIMITER DETECTION (Enhanced for Multiple Formats)
# ------------------------------------------------------------
# Detect common delimiters: , ; | : TAB ~ ^ * SPACE
common_delimiters=',;|:\t~^* '

# Read first non-empty line to avoid empty header issues
first_line=$(grep -m 1 -v '^[[:space:]]*$' "$csv_file")

# Count occurrences of potential delimiters and pick the most frequent
delimiter=$(echo "$first_line" | grep -o "[$common_delimiters]" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')

# Special handling for tab or missing delimiter
if [ -z "$delimiter" ]; then
    if echo "$first_line" | grep -q $'\t'; then
        delimiter=$'\t'
    else
        delimiter=","
    fi
fi

# Display the detected delimiter clearly for user
case "$delimiter" in
    $'\t') echo "Detected delimiter: TAB" ;;
    " ") echo "Detected delimiter: SPACE" ;;
    *) echo "Detected delimiter: '$delimiter'" ;;
esac

# ------------------------------------------------------------
# COLUMN EXTRACTION AND NUMERICAL DETECTION
# ------------------------------------------------------------
# Display column headers with their index
echo "Columns found in $csv_file:"
head -n 1 "$csv_file" | sed "s/$delimiter/\n/g" | nl

# Estimate number of fields
num_fields=$(head -n 1 "$csv_file" | sed "s/[^$delimiter]//g" | wc -c)
num_fields=$((num_fields + 1))

# Create a small sample for analysis
tail -n +2 "$csv_file" | head -n 20 > sample_rows.csv

# Detect numerical columns dynamically using AWK pattern matching
echo "Detecting numerical columns..."
num_indexes=()
for ((i=1; i<=num_fields; i++)); do
    if awk -F"$delimiter" -v col="$i" '{
        gsub(/^"|"$/, "", $col)
        if ($col !~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) exit 1
    }' sample_rows.csv; then
        num_indexes+=("$i")
    fi
done
echo "Automatically detected numerical columns: ${num_indexes[*]}"

# Allow user override for flexibility
read -p "Use these columns? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    read -p "Enter column numbers manually (e.g., 1,2,4): " manual_cols
    IFS=',' read -ra num_indexes <<< "$manual_cols"
fi

# ------------------------------------------------------------
# SUMMARY GENERATION
# ------------------------------------------------------------
output="../summary.md"
echo "# Feature Summary for $(basename "$csv_file")" > "$output"
echo "" >> "$output"
echo "## Feature Index and Names" >> "$output"
head -n 1 "$csv_file" | sed "s/$delimiter/\n/g" | nl >> "$output"
echo "" >> "$output"
echo "## Statistics (Numerical Features)" >> "$output"
echo "| Index | Feature | Min | Max | Mean | StdDev |" >> "$output"
echo "|-------|---------|-----|-----|------|--------|" >> "$output"

# Parse headers into array
IFS="$delimiter" read -ra headers <<< "$(head -n 1 "$csv_file")"

# Compute stats for each detected numerical column
for i in "${!num_indexes[@]}"; do
    col="${num_indexes[$i]}"
    index=$((i + 1))
    col_name=$(echo "${headers[$((col-1))]}" | sed 's/"//g')

    # Use AWK to calculate min, max, mean, stddev efficiently
    awk -F"$delimiter" -v col="$col" 'NR > 1 {
        gsub(/^"|"$/, "", $col)
        if ($col ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) print $col
    }' "$csv_file" | \
    awk -v idx="$index" -v name="$col_name" 'BEGIN {
        min=1e10; max=-1e10; sum=0; sumsq=0; count=0
    }
    {
        val = $1
        if (val < min) min = val
        if (val > max) max = val
        sum += val
        sumsq += val^2
        count++
    }
    END {
        if (count > 0) {
            mean = sum / count
            stddev = sqrt(sumsq / count - mean^2)
            printf "| %d | %s | %.2f | %.2f | %.3f | %.3f |\n", idx, name, min, max, mean, stddev
        }
    }' >> "$output"
done

# ------------------------------------------------------------
# CLEANUP
# ------------------------------------------------------------
mv "$csv_file" ../
cd ..
rm -r dataset_temp sample_rows.csv 2>/dev/null

echo "✅ Summary written to summary.md"
