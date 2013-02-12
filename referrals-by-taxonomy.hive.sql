CREATE EXTERNAL TABLE referrals_by_speciality (
  referring_doc_data_taxonomy_classification STRING,
  doc_referred_to_data_taxonomy_classification STRING,
  number_of_patients INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION 's3://rweald-data-dumps/referrals-by-speciality';


CREATE EXTERNAL TABLE referrals (
  referring_doc_npi STRING,
  doc_referred_to_npi STRING,
  number_patients INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION 's3://rweald-data-dumps/referrals';


CREATE EXTERNAL table npi_to_taxonomy (
  npi_number STRING,
  entity_type INT,
  organization_name STRING,
  last_name STRING,
  first_name STRING,
  middle_name STRING,
  prefix_text STRING,
  taxonomy_code STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION 's3://rweald-data-dumps/npi-to-taxonomy/';

CREATE EXTERNAL TABLE healthcare_provider_taxonomy (
  code STRING,
  type_of_provider STRING,
  classification STRING,
  specialization STRING,
  definition STRING,
  notes STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION 's3://rweald-data-dumps/healthcare-provider-taxonomy';


INSERT OVERWRITE TABLE referrals_by_speciality
SELECT
  referring_doc_data.classification,
  doc_referred_to_data.classification,
  SUM(number_of_patients) AS number_patients
FROM (
  SELECT
    referring_doc_data.taxonomy_code as referring_taxonomy_code,
    doc_referred_to_data.taxonomy_code as referred_to_taxonomy_code,
    SUM(number_patients) AS number_of_patients
  FROM referrals
  JOIN npi_to_taxonomy referring_doc_data ON referring_doc_data.npi_number = referrals.referring_doc_npi
  JOIN npi_to_taxonomy doc_referred_to_data ON doc_referred_to_data.npi_number = referrals.doc_referred_to_npi
  WHERE
    (referring_doc_data.entity_type = 1)
    AND
    (doc_referred_to_data.entity_type = 1)
  GROUP BY
    referring_doc_data.taxonomy_code,
    doc_referred_to_data.taxonomy_code;
) by_taxonomy
JOIN healthcare_provider_taxonomy referring_doc_data on referring_doc_data.code = by_taxonomy.referring_taxonomy_code
JOIN healthcare_provider_taxonomy doc_referred_to_data on doc_referred_to_data.code = by_taxonomy.referred_to_taxonomy_code
GROUP BY
  referring_doc_data.classification,
  doc_referred_to_data.classification
