library(ggplot2)
library(plyr)
library(maps)

# Combine the referrals data with the NPI database to get state location of Doc
referrals <- read.csv("~/code/docgraph-data-analysis/refer.2011.sample2.csv", header = F)
colnames(referrals) <- c("doc1", "doc2", "number.of.patients")

npi.to.state <- read.csv("~/Downloads/Physician provider ID (NPI) data dump/npi-to-state.csv", as.is  =  T)
colnames(npi.to.state) <- c("npi.number", "state")

tmp1 <- merge(referrals, npi.to.state, by.x = "doc1", by.y = "npi.number")
colnames(tmp1) <- c("doc1", "doc2", "number.of.patients", "doc1.state")
refs.with.state <- merge(tmp1, npi.to.state, by.x = "doc2", by.y = "npi.number")
colnames(refs.with.state) <- c("doc2", "doc1", "number.of.patients", "doc1.state", "doc2.state")

# Aggregate referrals on a state level and remove any badly formatted states
patients.by.state <- ddply(refs.with.state, c("doc1.state", "doc2.state"), summarize, patients = sum(number.of.patients))

patients.by.state <- subset(patients.by.state, (doc1.state %in% state.abb) & (doc2.state %in% state.abb))
out.of.state <- subset(patients.by.state, doc1.state != doc2.state)


# Compute the indegree and outdegree for each state in preperation for graphing
in.degree <- ddply(out.of.state, c("doc2.state"), summarize, indegree = sum(patients))
out.degree <- ddply(out.of.state, c("doc1.state"), summarize, outdegree = sum(patients))

degree.by.state <- merge(in.degree, out.degree, by.x = "doc2.state", by.y = "doc1.state")
colnames(degree.by.state) <- c("state", "indegree", "outdegree")

degree.by.state$ration.out.vs.in <- degree.by.state$outdegree / degree.by.state$indegree

#Get state data in a format that can be merged with Maps state names

state.names <- data.frame(region = tolower(state.name), abbreviation = state.abb)
degree.by.state <- merge(degree.by.state, state.names, by.x = "state", by.y = "abbreviation")

#choropleth plot of indegree vs outdegree for each state

state_df <- map_data("state")
choropleth <- merge(state_df, degree.by.state, by = "region", all.x = T)
choropleth[with(choropleth, is.na(ration.out.vs.in)),]$ration.out.vs.in <- 1
choropleth <- choropleth[order(choropleth$order), ]

#choropleth$ratio_d <- cut(choropleth$ration.out.vs.in, 
                          #breaks = seq(from = min(choropleth$ration.out.vs.in), 
                                       #to = max(choropleth$ration.out.vs.in), by = 0.01))

choropleth$ratio_d <- cut(choropleth$ration.out.vs.in, breaks = 9)

ggplot(choropleth, aes(long, lat, group = group)) +
  geom_polygon(aes(fill= ration.out.vs.in), size=0.2) +
  scale_fill_gradient(low = rgb(252,187,136, maxColorValue=255),
                      high = rgb(215,73,25, maxColorValue=255),
                      name = "Log Scale Number of Patients")


# Matrix plot of Inter-State referrals
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
