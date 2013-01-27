library(ggplot2)
library(plyr)
library(maps)
source("state-level-graph-analysis/utils.R")

distance.by.state <- read.csv("distance-by-state.csv")
distance.by.state <- subset(distance.by.state, state_of_origin %in% state.abb)


png("distance-by-state.png", width=40, height = 25, units = "in", res = 72)
ggplot(distance.by.state) +
  geom_bar(aes(reorder(state_of_origin, -avg_distance), avg_distance), state = "identity") +
  labs(title = "Average Distance of Referral By State", x = "State", y = "Average Distance (km)") +
  theme(plot.title = element_text(size = 35),
        axis.title.x = element_text(size = 30),
        axis.title.y = element_text(size = 30),
        axis.text.x = element_text(size = 20),
        axis.text.y = element_text(size = 20))

dev.off()


