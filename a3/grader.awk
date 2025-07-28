BEGIN {
    FS = ","  # Set the field separator to comma
    print "Processing student grades...\n"   # \n: new line
}

NR == 1 {
    # Skip the header row (avoid column names)
    next
}

{
    name = $2      # Extract student name from column 2
    total = 0

    # Summing up the totalScores for a student
    # Loop through grade fields (starting from column 3)
    for (i = 3; i <= NF; i++) {    # NF: number of fields on the current line
        total += $i
    }

    # Store total in associative array (dictionary)
    totalScores[name] = total

    # Calculate average using a user-defined function
    avg = calc_avg(total, NF - 2)    # -2 --> first 2 fields are not grades
    averages[name] = avg

    # Use if-statement to determine pass/fail
    if (avg >= 70) {
        status[name] = "Pass"
    } else {
        status[name] = "Fail"
    }

    # Track highest and lowest scoring students
    if (NR == 2 || total > maxScore) {    # NR = number on record: line number  being processed
        maxScore = total
        topStudent = name
    }

    if (NR == 2 || total < minScore) {
        minScore = total
        lowStudent = name
    }
}

# User-defined function to calculate average
function calc_avg(sum, count) {
    return sum / count
}

END {
    print "Student Summary:\n"

    # Loop through associative array to print output
    for (name in totalScores) {
        printf "Name: %-10s | Total: %3d | Avg: %.2f | Status: %s\n", \
               name, totalScores[name], averages[name], status[name]
    }

    # Print top and lowest scoring students
    print "\nTop Scorer   : " topStudent " with score " maxScore
    print "Lowest Scorer: " lowStudent " with score " minScore
}

