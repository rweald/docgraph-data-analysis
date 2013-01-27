-- This query relies on a UDF that is available on Github
-- https://github.com/sharethrough/hive-udfs
-- You will need to build this UDF and then copy it to your cluster storage
ADD JAR hdfs:///data/jars/hive-udfs-assembly-0.0.1.jar;
CREATE TEMPORARY FUNCTION haversine_distance AS 'com.sharethrough.hive.udfs.HaversinceDistance';


SELECT
  doc1_state,
  AVG(distance) as avg_distance,
  stddev_pop(distance) as std_distance
FROM (
  SELECT
    doc1_state,
    haversine_distance(doc1_lon, doc1_lat, doc2_lon, doc2_lat) as distance
  FROM (
    SELECT
      doc1_location.state as doc1_state,
      doc1_location.lon as doc1_lon,
      doc1_location.lat as doc1_lat,
      doc2_location.lon as doc2_lon,
      doc2_location.lat as doc2_lat
    FROM referrers
    JOIN npi_to_location doc1_location ON doc1_location.npi_number = referrers.doc1
    JOIN npi_to_location doc2_location ON doc2_location.npi_number = referrers.doc2
  ) sub1
  WHERE
    (doc1_lon IS NOT NULL)
    AND
    (doc2_lon IS NOT NULL)
    AND
    (doc1_lat IS NOT NULL)
    AND
    (doc2_lat IS NOT NULL)
) sub2
GROUP BY doc1_state
