# Takes NPI Data dump file as first argument
# Outputs "physician_npi_number,physician practice zip code"

#!/usr/bin/env python
import sys, csv

input_csv = csv.reader(open(sys.argv[1]))
output_csv = csv.writer(sys.stdout)

input_csv.next() # remove the header
output_csv.writerow(["npi number", "zip code"])

for values in input_csv:
  zip_code = values[32][:5]
  npi_number = values[0]
  output_csv.writerow([npi_number, zip_code])

