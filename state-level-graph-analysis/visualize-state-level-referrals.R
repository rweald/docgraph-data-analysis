library(ggplot2)
library(plyr)
library(maps)

states <- c("AL","AK","AZ","AR","CA","CO","CT","DE","DC",
            "FL","GA","HI","ID","IL","IN","IA","KS","KY",
            "LA","ME","MT","NE","NV","NH","NJ","NM","NY",
            "NC","ND","OH","OK","OR","MD","MA","MI","MN","MS","MO",
            "PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

referrals <- read.csv("~/code/docgraph-data-analysis/refer.2011.sample2.csv", header = F)
colnames(referrals) <- c("doc1", "doc2", "number.of.patients")

npi.to.state <- read.csv("~/Downloads/Physician provider ID (NPI) data dump/npi-to-state.csv", as.is  =  T)
colnames(npi.to.state) <- c("npi.number", "state")

tmp1 <- merge(referrals, npi.to.state, by.x = "doc1", by.y = "npi.number")
colnames(tmp1) <- c("doc1", "doc2", "number.of.patients", "doc1.state")
refs.with.state <- merge(tmp1, npi.to.state, by.x = "doc2", by.y = "npi.number")
colnames(refs.with.state) <- c("doc2", "doc1", "number.of.patients", "doc1.state", "doc2.state")

patients.by.state <- ddply(refs.with.state, c("doc1.state", "doc2.state"), summarize, patients = sum(number.of.patients))

out.of.state <- subset(patients.by.state, (doc1.state %in% states) & (doc2.state %in% states))
out.of.state <- subset(out.of.state, doc1.state != doc2.state)

default.color <- "ivory"

png("inter-state-referrals-heatmap.png", width = 3600, height = 2025)

ggplot(out.of.state, aes(doc1.state, doc2.state)) +
  geom_tile(aes(fill = patients), colour = default.color) +
  scale_fill_gradient(low = default.color,
                      high = "orange",
                      name = "Log Scale Number of Patients") +
  labs(x = "Referring State",
       y = "State Being Referred To",
       title = "DocGraph Inter-State Referrals") +
  theme(plot.background = element_rect(fill = "white", colour = default.color),
        panel.background = element_rect(fill = default.color, colour = default.color),
        axis.ticks = element_blank(),
        axis.text.x = element_text(angle = 90))

dev.off()
