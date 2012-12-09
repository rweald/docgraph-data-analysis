# Reads a 2-tuple from STDIN (physician_npi_number, zip_code)
# Also takes a database mapping Zip Codes to Location (lat, long)
# This script uses the format from the database located here:
# http://federalgovernmentzipcodes.us/
# Writes to STDOUT the input tuple enriched with
# lat and long
#!/usr/bin/env python
import sys, csv

input_csv = csv.reader(sys.stdin)
zipcode_csv = csv.reader(open(sys.argv[1]))
output_csv = csv.writer(sys.stdout)

# Load the ZipCode to Lat Long
# database into memory to make lookups fast
zipcode_csv.next() # remove header
zip_codes_to_location = {}
for items in zipcode_csv:
  geo = {
    'lat': items[5],
    'long': items[6]
  }
  zip_codes_to_location[int(items[0])] = geo

header = ["npi_number", "zip", "lat", "long"]
output_csv.writerow(header)
input_csv.next() # remove header
n_rows, n_uncodeable = 0,0
for (npi_number, zip_code) in input_csv:
  n_rows += 1
  try:
    zip_code = int(zip_code)
    if zip_code in zip_codes_to_location:
      geo = zip_codes_to_location[zip_code]
      output_csv.writerow([npi_number, zip_code, geo['lat'], geo['long']])
    else:
      n_uncodeable += 1
  except Exception:
    n_uncodeable += 1

sys.stderr.write("number of total lines = " + str(n_rows) + "\n")
sys.stderr.write("number of uncodeable zipcodes = " + str(n_uncodeable) + "\n")
