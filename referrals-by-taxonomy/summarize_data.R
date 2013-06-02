library(plyr)
library(R2HTML)

raw_referrals <- read.csv("~/Downloads/referral-by-taxonomy-graph.csv")
taxonomy <- read.csv("~/Downloads/health-care-provider-code-taxonomy.csv", as.is = TRUE)

taxonomy[with(taxonomy, Specialization == ""),]$Specialization <- "General"

interm1 <- merge(raw_referrals, taxonomy, by.x = "referring_doctor_taxonomy", by.y = "Code")
referrals_by_raw_taxonomy <- merge(interm1, taxonomy, by.x = "doctor_referred_to_taxonomy", by.y = "Code")

referrals_by_raw_taxonomy <- transform(referrals_by_raw_taxonomy, type.x = paste(Classification.x, Specialization.x, sep = " - "),
                                       type.y = paste(Classification.y, Specialization.y, sep = " - "))


referrals_by_classification <- ddply(referrals_by_raw_taxonomy, c("type.x", "type.y"), summarise, num_patients = sum(number_patients))
referrals_by_classification <- subset(referrals_by_classification, num_patients > 10000)

referrals_by_classification <- referrals_by_classification[order(-referrals_by_classification$num_patients),]

write.csv(referrals_by_classification, file = "~/Downloads/referrals-by-classification.csv", row.names = FALSE)

non.overlapping <- subset(referrals_by_classification, as.character(type.x) != as.character(type.y))

write.csv(non.overlapping, file = "~/Downloads/non-overlapping-referrals-by-class.csv", row.names = FALSE)

top.refs <- head(referrals_by_classification, n = 20)
top.non.overlapping <- head(non.overlapping, n = 20)

#Write out the HTML tables needed for the blog post
HTML(transform(top.refs, num_patients = format(num_patients, big.mark=",", scientific=FALSE)),
     file = "~/Downloads/refs-by-class.html", row.names = FALSE)

HTML(transform(top.non.overlapping, num_patients = format(num_patients, big.mark=",", scientific=FALSE)),
     file = "~/Downloads/non-overlapping-refs-by-class.html", row.names = FALSE)
