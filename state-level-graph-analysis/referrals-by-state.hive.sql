SELECT
  doc1_state,
  doc2_state,
  SUM(number_patients) as patients
FROM (
  SELECT
    doc1,
    doc2,
    number_patients,
    doc1_state.state as doc1_state,
    doc2_state.state as doc2_state
  FROM referrers
  JOIN npi_to_state doc1_state ON doc1_state.npi_number = referrers.doc1
  JOIN npi_to_state doc2_state ON doc2_state.npi_number = referrers.doc2
) sub1
GROUP BY doc1_state, doc2_state

