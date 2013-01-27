# Analyzing Out-of-State Referrals

All the code used to perform the analysis found in my post:

http://isurfsoftware.com/blog/2013/01/27/analyzing-out-of-state-patient-referrals-using-docgraph/

## Instructions

Unfortunately this analysis is not as easy to duplicate as my first visualization as it uses the full dataset rather than a sample. 
If you follow the steps below you should be able to reproduce the analysis using the DocGraph dataset

There are two phases to get to the final product.

####Phase 1

Phase 1 is generating a CSV containing ```referring_doc_state,state_of_doc_referred_to,number_of_patients```.

If you want to use the full data set this can be quite a computationally intense process. The first step is to generate
a CSV mapping NPI numbers to states. This can be achieved using the following unix sequence:

```
cut -d "," -f 1,32 | ruby map-npi-to-state.rb > npi_to_state.csv
```

You will then need to join this data with the DocGraph data by NPI number. This is the computationally expensive part at the DocGraph dataset is 40+ million rows.

You have a couple ways you can do this. 
If you have a beefy box with lots of RAM and you aren't in a hurry you can use the R script I provided [here](https://github.com/rweald/docgraph-data-analysis/blob/master/state-level-graph-analysis/generate-referrals-by-state-from-sample.R)
I personally don't have enough RAM or patient for that so I used a small Hive cluster on [Amazon EMR](http://aws.amazon.com/elasticmapreduce/). If you choose to use Hive I have included all the SQL you should need to setup your tables [here](https://github.com/rweald/docgraph-data-analysis/blob/master/state-level-graph-analysis/create-tables.hive.sql). 

Once you have your data in Hive it is easy to generate the desired CSV, simply run the query found in [this file](https://github.com/rweald/docgraph-data-analysis/blob/master/state-level-graph-analysis/referrals-by-state.hive.sql).

The query can be executed as follows:

```
hive -f referrals-by-state.hive.sql | tr "\t" "," > referrals-by-state.csv
```

Once you have that CSV you are ready for phase 2.

####Phase 2
The second phase is much easier than the first phase. All you have to do is execute 1 R script that can be found [here](https://github.com/rweald/docgraph-data-analysis/blob/master/state-level-graph-analysis/visualize-state-level-referrals.R)

```
R --slave --silent < visualize-state-level-referrals.R
```

