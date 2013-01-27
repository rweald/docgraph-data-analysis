CREATE TABLE referrers (
  doc1 STRING,
  doc2 STRING,
  number_patients STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TextFile;

LOAD DATA INPATH 'hdfs:///user/ec2-user/data/referrers.csv' INTO TABLE referrers;

create table npi_to_state (
  npi_number STRING,
  state STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TextFile;

LOAD DATA INPATH 'hdfs:///user/ec2-user/data/npi_to_state.csv' INTO TABLE npi_to_state;

create external table npi_to_location_tmp (
  npi_number STRING,
  zip INT,
  lon DOUBLE,
  lat DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION 'hdfs:///user/ec2-user/data/npi_to_location';

create table npi_to_location AS
SELECT
  npi_to_location_tmp.npi_number as npi_number
  lon,
  lat,
  nps.state
FROM npi_to_location_tmp
JOIN npi_to_state nps on nps.npi_number = npi_to_location_tmp.npi_number
