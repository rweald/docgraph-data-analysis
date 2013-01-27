library(plyr)
source("state-level-graph-analysis/utils.R")

# Combine the referrals data with the NPI database to get state location of Doc
print("Loading Raw Data")
referrals <- read.csv("~/code/docgraph-data-analysis/refer.2011.sample10.csv", header = F)
colnames(referrals) <- c("doc1", "doc2", "number.of.patients")

npi.to.state <- read.csv("~/Downloads/Physician provider ID (NPI) data dump/npi-to-state.csv", as.is  =  T)
colnames(npi.to.state) <- c("npi.number", "state")

tmp1 <- merge(referrals, npi.to.state, by.x = "doc1", by.y = "npi.number")
colnames(tmp1) <- c("doc1", "doc2", "number.of.patients", "doc1.state")
refs.with.state <- merge(tmp1, npi.to.state, by.x = "doc2", by.y = "npi.number")
colnames(refs.with.state) <- c("doc2", "doc1", "number.of.patients", "doc1.state", "doc2.state")

print("Aggregating and rolling up data")
# Aggregate referrals on a state level and remove any badly formatted states
patients.by.state <- ddply(refs.with.state, c("doc1.state", "doc2.state"), summarize, patients = sum(number.of.patients))

write.csv(patients.by.state, file = "referrals-by-state-from-sample.csv")

