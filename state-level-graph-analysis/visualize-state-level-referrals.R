library(ggplot2)
library(plyr)
library(maps)
source("state-level-graph-analysis/utils.R")

patients.by.state <- read.csv("referrals-by-state.csv", as.is = TRUE)
colnames(patients.by.state) <- c("doc1.state", "doc2.state", "patients")

patients.by.state <- subset(patients.by.state, (doc1.state %in% state.abb) & (doc2.state %in% state.abb))
out.of.state <- subset(patients.by.state, doc1.state != doc2.state)
in.state <- subset(patients.by.state, doc1.state == doc2.state)


# Compute the indegree and outdegree for each state in preperation for graphing
in.degree <- ddply(out.of.state, c("doc2.state"), summarize, indegree = sum(patients))
out.degree <- ddply(out.of.state, c("doc1.state"), summarize, outdegree = sum(patients))

degree.by.state <- merge(in.degree, out.degree, by.x = "doc2.state", by.y = "doc1.state")
colnames(degree.by.state) <- c("state", "indegree", "outdegree")

#degree.by.state$ration.out.vs.in <- degree.by.state$outdegree / degree.by.state$indegree

all.by.state <- merge(degree.by.state, in.state, by.x = "state", by.y = "doc1.state")

all.by.state <- transform(all.by.state, total.referrals = patients + indegree + outdegree) 
all.by.state <- transform(all.by.state, percent.in.state = (patients / total.referrals), 
                          percent.from.out.of.state = (indegree / total.referrals),
                          percent.leaving.state = (outdegree / total.referrals),
                          ration.out.vs.in = (outdegree / indegree))

#Get state data in a format that can be merged with Maps state names
state.names <- data.frame(region = tolower(state.name), abbreviation = state.abb)
all.by.state <- merge(all.by.state, state.names, by.x = "state", by.y = "abbreviation")


print("starting to draw plots")
################################################################################
#basic statistical plots of state level data

png("general-statistical-plots.png", width=40, height = 25, units = "in", res = 72)

text.theme <- theme(plot.title = element_text(size = 35),
                    axis.title.x = element_text(size = 30),
                    axis.title.y = element_text(size = 30),
                    axis.text.x = element_text(size = 20),
                    axis.text.y = element_text(size = 20))


g1 <- ggplot(all.by.state) +
  geom_density(aes(percent.in.state), fill = "lightblue") +
  ggtitle("Distribution - Percent of Total Referrals That Stay In State") +
  text.theme

g2 <- ggplot(all.by.state) +
  geom_density(aes(percent.from.out.of.state), fill = "lightcoral") +
  ggtitle("Distribution - Percent of Total Referrals From Out of State") + 
  text.theme

g3 <- ggplot(all.by.state) +
  geom_density(aes(percent.leaving.state), fill = "mediumaquamarine") +
  ggtitle("Distribution - Percent of Total Referrals That Leave State") +
  text.theme

multiplot(g1, g2, g3, cols = 2)

dev.off()

################################################################################
#choropleth plot of indegree vs outdegree for each state
state_df <- map_data("state")

choropleth <- merge(state_df, all.by.state, by = "region", all.x = T)
choropleth[with(choropleth, is.na(ration.out.vs.in)),]$ration.out.vs.in <- 1
choropleth <- choropleth[order(choropleth$order), ]

steps <- seq(from = round(min(choropleth$ration.out.vs.in), digits = 2), to = round(max(choropleth$ration.out.vs.in), digits = 2), by = 0.05)

png("outbound-vs-inbound-choropleth-dev.png", width=40, height = 25, units = "in", res = 72)
ggplot(choropleth, aes(long, lat, group = group)) +
  geom_polygon(aes(fill= ration.out.vs.in)) +
  geom_polygon(size = 1, colour = "black", fill = NA) +
  scale_fill_gradient(low = rgb(252,187,136, maxColorValue=255),
                      high = rgb(215,73,25, maxColorValue=255),
                      name = "",
                      labels = steps,
                      breaks = steps) +
  labs(title = "Ration of Outbound vs Inboud Referrals") +
  blank_theme() +
  custom_map_theme()

dev.off()

################################################################################
#choropleth plot of percent in-state
state_df <- map_data("state")

choropleth <- merge(state_df, all.by.state, by = "region", all.x = T)
choropleth[with(choropleth, is.na(percent.in.state)),]$percent.in.state <- mean(choropleth$percent.in.state)
choropleth <- choropleth[order(choropleth$order), ]

steps <- seq(from = 0.0, to = 1.0, by = 0.05)

png("percent-in-state-choropleth-dev.png", width=40, height = 25, units = "in", res = 72)

ggplot(choropleth, aes(long, lat, group = group)) +
  geom_polygon(aes(fill= percent.in.state)) +
  geom_polygon(size=1, colour = "black", fill = NA) +
  scale_fill_gradient(low = rgb(252,187,136, maxColorValue=255),
                      high = rgb(215,73,25, maxColorValue=255),
                      name = "",
                      labels = steps,
                      breaks = steps) +
  labs(title = "Percent of Referrals That Stay In State") +
  blank_theme() +
  custom_map_theme()

dev.off()

################################################################################
#choropleth plot of percent of referrals that leave state

state_df <- map_data("state")

choropleth <- merge(state_df, all.by.state, by = "region", all.x = T)
choropleth[with(choropleth, is.na(percent.leaving.state)),]$percent.leaving.state <- mean(choropleth$percent.leaving.state)
choropleth <- choropleth[order(choropleth$order), ]

steps <- seq(from = 0.0, to = 1.0, by = 0.05)

png("percent-leaving-state-choropleth-dev.png", width=40, height = 25, units = "in", res = 72)
ggplot(choropleth, aes(long, lat, group = group)) +
  geom_polygon(aes(fill= percent.leaving.state)) +
  geom_polygon(size=1, colour = "black", fill = NA) +
  scale_fill_gradient(low = rgb(252,187,136, maxColorValue=255),
                      high = rgb(215,73,25, maxColorValue=255),
                      name = "",
                      labels = steps,
                      breaks = steps) +
  labs(title = "Percent of Referrals That Leave State") +
  blank_theme() +
  custom_map_theme()

dev.off()

################################################################################
# Matrix plot of Inter-State referrals

default.color <- "ivory"

png("inter-state-referrals-heatmap.png", width = 3600, height = 2025)

ggplot(out.of.state, aes(doc1.state, doc2.state)) +
  geom_tile(aes(fill = patients), colour = default.color) +
  scale_fill_gradient(low = default.color,
                      high = "orange",
                      name = "Number of Patients") +
  labs(x = "Referring State",
       y = "State Being Referred To",
       title = "DocGraph Inter-State Referrals") +
  theme(plot.background = element_rect(fill = "white", colour = default.color),
        panel.background = element_rect(fill = default.color, colour = default.color),
        axis.ticks = element_blank(),
        axis.text.x = element_text(angle = 90)) +
  custom_map_theme() +
  theme(axis.text.x = element_text(size = 35),
        axis.text.y = element_text(size = 35),
        axis.title.x = element_text(size = 45),
        axis.title.y = element_text(size = 45),
        legend.text = element_text(size = 40),
        legend.position = "right",
        legend.key.height = unit(0.05, "npc"),
        legend.key.width = unit(0.025, "npc"))

dev.off()
