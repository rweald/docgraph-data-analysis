#Extract Physical Therapists From Data Set

###Usage

The first step is to extract the NPI numbers of physical therapists from the NIP database:

```
cat <path to npi_dump.csv> | ./extract-npi-numbers-for-physical-therapists.sh > physical-therapist-npi-numbers.csv
```
