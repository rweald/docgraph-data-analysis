library(plyr)

raw_referrals <- read.csv("~/Downloads/referral-by-taxonomy-graph.csv")
taxonomy <- read.csv("~/Downloads/health-care-provider-code-taxonomy.csv")


interm1 <- merge(raw_referrals, taxonomy, by.x = "referring_doctor_taxonomy", by.y = "Code")
referrals_by_raw_taxonomy <- merge(interm1, taxonomy, by.x = "doctor_referred_to_taxonomy", by.y = "Code")

referrals_by_classification <- ddply(referrals_by_raw_taxonomy, c("Classification.x", "Classification.y"), summarise, num_patients = sum(number_patients))

referrals_by_classification <- referrals_by_classification[order(-referrals_by_classification$num_patients),]

write.csv(referrals_by_classification, file = "~/Downloads/referrals-by-classification.csv", row.names = FALSE)

non.overlapping <- subset(referrals_by_classification, Classification.x != Classification.y)

