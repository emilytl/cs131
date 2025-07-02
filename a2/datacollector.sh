#!/bin/bash

# Prompt for dataset URL
read -p "Enter the URL to a CSV dataset (ZIP or CSV): " url

# Create a temporary directory
mkdir -p dataset_temp
cd dataset_temp || exit

# Download file using curl
curl -L "$url" -o data.zip

# Extract CSV from zip or treat as raw CSV
if file data.zip | grep -q "Zip archive"; then
    unzip -q data.zip
    csv_file=$(find . -name "*.csv" | head -n 1)
else
    mv data.zip data.csv
    csv_file="data.csv"
fi

# Confirm file exists
if [ ! -f "$csv_file" ]; then
    echo "No CSV file found. Exiting."
    exit 1
fi

# Detect delimiter
delimiter=$(head -n 1 "$csv_file" | grep -o '[,;]' | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')
echo "Detected delimiter: '$delimiter'"

# Show column headers with index numbers
echo "Columns found in $csv_file:"
head -n 1 "$csv_file" | sed "s/$delimiter/\n/g" | nl

# Auto-detect numerical columns
echo "Detecting numerical columns..."
num_fields=$(head -n 1 "$csv_file" | sed "s/[^$delimiter]//g" | wc -c)
num_fields=$((num_fields + 1))

num_indexes=()
tail -n +2 "$csv_file" | head -n 20 > sample_rows.csv

for ((i=1; i<=num_fields; i++)); do
    if awk -F"$delimiter" -v col="$i" '{
        gsub(/^"|"$/, "", $col)
        if ($col !~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) exit 1
    }' sample_rows.csv; then
        num_indexes+=("$i")
    fi
done

echo "Automatically detected numerical columns: ${num_indexes[*]}"

# Allow user to override
read -p "Use these columns? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    read -p "Enter column numbers manually (e.g., 1,2,4): " manual_cols
    IFS=',' read -ra num_indexes <<< "$manual_cols"
fi

# Create summary.md
output="../summary.md"
echo "# Feature Summary for $(basename "$csv_file")" > "$output"
echo "" >> "$output"
echo "## Feature Index and Names" >> "$output"
head -n 1 "$csv_file" | sed "s/$delimiter/\n/g" | nl >> "$output"
echo "" >> "$output"
echo "## Statistics (Numerical Features)" >> "$output"
echo "| Index | Feature | Min | Max | Mean | StdDev |" >> "$output"
echo "|-------|---------|-----|-----|------|--------|" >> "$output"

# Parse headers
IFS="$delimiter" read -ra headers <<< "$(head -n 1 "$csv_file")"

# Generate stats for each selected column
for i in "${!num_indexes[@]}"; do
    col="${num_indexes[$i]}"
    index=$((i + 1))
    col_name=$(echo "${headers[$((col-1))]}" | sed 's/"//g')

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

# Cleanup
mv "$csv_file" ../
cd ..
rm -r dataset_temp sample_rows.csv 2>/dev/null

echo "Summary written to summary.md"




