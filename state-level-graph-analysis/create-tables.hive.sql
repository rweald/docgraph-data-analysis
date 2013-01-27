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

