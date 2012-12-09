#!/usr/bin/env python
import sys, csv

input_csv = csv.reader(sys.stdin)
zipcode_csv = csv.reader(sys.argv[1])
zip_codes_to_location = {}

output_csv = csv.writer(sys.stdout)

zipcode_csv.next() # remove header
for items in zipcode_csv:
  geo = {
    'lat': items[5],
    'long': items[6]
  }
  zip_codes_to_location[items[0]] = geo


NPISeenFirst,NPISeenSecond,PatientTransactionCount
#header = [
  #"first_doctor",
  #"first_doctor_zip",
  #"first_doctor_lat",
  #"first_doctor_long",
  #"second_doctor",
  #"second_doctor_zip",
  #"second_doctor_lat",
  #"second_doctor_long",
  #"number_of_patients"
#]

header = ["nip_number", "zip", "lat", "long"]

output_csv.writerow(header)

for (doc_1, zip_code) in input_csv:
  geo = zip_codes_to_location[zip_code]
