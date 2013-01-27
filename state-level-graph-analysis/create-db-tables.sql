CREATE TABLE npi_to_state (
  npi_number INT,
  state VARCHAR(255)
);

create index npi_number_index on npi_to_state (npi_number);

CREATE TABLE referrers (
  doc1 VARCHAR(255),
  doc2 VARCHAR(255),
  number_patients VARCHAR(255)
);

create index doc1_index on referrers (doc1);
create index doc2_index on referrers (doc2);

--------------------------------------------------------------------------------
-- load data into local DB if you so desire.
-- If loading into remote DB you are probably better off using mysqlimport
LOAD DATA LOCAL INFILE '/Users/Ryan/Downloads/Physician provider ID (NPI) data dump/npi-to-state.csv'
INTO TABLE npi_to_state
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

LOAD DATA INFILE '/Users/Ryan/code/docgraph-data-analysis/refer.2011.no.last.line.csv'
INTO TABLE referrers
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

