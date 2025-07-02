# DataCollector Shell Script

## What this command does

`datacollector.sh` is a bash shell script that automates downloading and summarizing CSV datasets from URLs, including zipped files.  
It is designed to work with tabular datasets from the UCI Machine Learning Repository and similar sources.

Key features:  
- Automatically downloads a dataset from a given URL (supports `.csv` and zipped `.zip` files)  
- Detects whether the CSV delimiter is a comma `,` or semicolon `;` and processes accordingly  
- Lists all column features with index numbers  
- Automatically detects numerical columns by sampling data values  
- Computes and generates a Markdown summary file (`summary.md`) with min, max, mean, and standard deviation for each numerical feature  

This tool simplifies the exploratory data analysis setup by quickly providing key dataset statistics without manual preprocessing.

---

## How to use this command

1. Ensure the script has execute permissions:

   ```bash
   chmod +x datacollector.sh

2. Run the script
   ./datacollector.sh

3. When prompted, enter the URL of the dataset. Example:
   https://archive.ics.uci.edu/static/public/186/wine+quality.zip

4. The script will detect the delimiter, display column headers with indexes, and automatically detect numerical columns.
Confirm whether to use the detected numerical columns or enter your own.

5. After processing, a summary.md file will be generated in the current directory containing a feature summary and statistics.

## Demo

```bash
$ ./datacollector.sh
Enter the URL to a CSV dataset (ZIP or CSV): https://archive.ics.uci.edu/static/public/186/wine+quality.zip
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  91353    0  91353    0     0   470k      0 --:--:-- --:--:-- --:--:--  472k
Detected delimiter: ';'
Columns found in ./winequality-white.csv:
     1  "fixed acidity"
     2  "volatile acidity"
     3  "citric acid"
     4  "residual sugar"
     5  "chlorides"
     6  "free sulfur dioxide"
     7  "total sulfur dioxide"
     8  "density"
     9  "pH"
    10  "sulphates"
    11  "alcohol"
    12  "quality"
Detecting numerical columns...
Automatically detected numerical columns: 1 2 3 4 5 6 7 8 9 10 11 12
Use these columns? (y/n): y
Summary written to summary.md

$ cat summary.md
# Feature Summary for winequality-white.csv

## Feature Index and Names
     1  "fixed acidity"
     2  "volatile acidity"
     3  "citric acid"
     4  "residual sugar"
     5  "chlorides"
     6  "free sulfur dioxide"
     7  "total sulfur dioxide"
     8  "density"
     9  "pH"
    10  "sulphates"
    11  "alcohol"
    12  "quality"

## Statistics (Numerical Features)
| Index | Feature              | Min   | Max   | Mean    | StdDev |
|-------|----------------------|-------|-------|---------|--------|
| 1     | fixed acidity        | 3.80  | 14.20 | 6.855   | 0.844  |
| 2     | volatile acidity     | 0.08  | 1.10  | 0.278   | 0.101  |
| 3     | citric acid          | 0.00  | 1.66  | 0.334   | 0.121  |
| 4     | residual sugar       | 0.60  | 65.80 | 6.391   | 5.072  |
| 5     | chlorides            | 0.01  | 0.35  | 0.046   | 0.022  |
| 6     | free sulfur dioxide  | 2.00  | 289.00| 35.308  | 17.005 |
| 7     | total sulfur dioxide | 9.00  | 440.00| 138.361 | 42.494 |
| 8     | density              | 0.99  | 1.04  | 0.994   | 0.003  |
| 9     | pH                   | 2.72  | 3.82  | 3.188   | 0.151  |
| 10    | sulphates            | 0.22  | 1.08  | 0.490   | 0.114  |
| 11    | alcohol              | 8.00  | 14.20 | 10.514  | 1.230  |
| 12    | quality              | 3.00  | 9.00  | 5.878   | 0.886  |

