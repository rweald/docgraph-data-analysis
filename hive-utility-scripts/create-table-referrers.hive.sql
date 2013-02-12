CREATE EXTERNAL TABLE referrals (
  referring_doc_npi STRING,
  doc_referred_to_npi STRING,
  number_patients INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION 's3://rweald-data-dumps/referrals';
