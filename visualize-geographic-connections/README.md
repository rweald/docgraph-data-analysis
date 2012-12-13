# Visualization of Geographic connections between doctors

## Instructions

This visualization relies on the 
[DocGraph](http://strata.oreilly.com/2012/11/docgraph-open-social-doctor-data.html)
dataset along with the full [NPPES data dump](http://nppes.viva-it.com/NPI_Files.html), and
a zipcode to lat long database which can be downloaded [here](http://federalgovernmentzipcodes.us/)

There are several data cleaning steps necessary before you can generate the visualization.

1. Extract CSV mapping physician NPI number to practice zip code

    ```
    $python extract_zip_codes.py <path to npi_dump_file>
    ```

2. Map NPI number to lat long coordinates

    ```
      $ cat <path_to_npi_zipcode_csv> | python map_npi_number_to_location.py <path to zipcode to lat long database>
    ```

3. Run the R script using your preferred method 
    
