library(ggplot2)
library(plyr)
library(maps)

multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  require(grid)

  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                    ncol = cols, nrow = ceiling(numPlots/cols))
  }

 if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

blank_theme <- function() {
  return(
         theme(axis.line=element_blank(),
               axis.text.x=element_blank(),
               axis.text.y=element_blank(),
               axis.ticks=element_blank(),
               axis.title.x=element_blank(),
               axis.title.y=element_blank(),
               panel.background=element_blank(),
               panel.border=element_blank(),
               panel.grid.major=element_blank(),
               panel.grid.minor=element_blank(),
               plot.background=element_blank(),
               legend.text = element_text(size = 16),
               legend.title = element_text(size = 16),
               legend.position = "right",
               plot.title = element_text(size=24))
         )
}

custom_map_theme <- theme(legend.position = "bottom",
                          plot.title = element_text(size = 50),
                          legend.text = element_text(size = 60),
                          legend.background = element_rect(size = 60),
                          legend.key.width = unit(0.075, "npc"),
                          legend.title = element_text(size = 40))


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
  ggtitle("Distribution - Percent of Total Referrals That Stay In State - Distribution") +
  text.theme

g2 <- ggplot(all.by.state) +
  geom_density(aes(percent.from.out.of.state), fill = "lightcoral") +
  ggtitle("Distribution - Percent of Total Referrals From Out of State") + 
  text.theme

g3 <- ggplot(all.by.state) +
  geom_density(aes(percent.leaving.state), fill = "mediumaquamarine") +
  ggtitle("Distribution - Percent of Total Referrals That Leave State - Distribution") +
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
  custom_map_theme

ggsave("outbound-vs-inbound-choropleth-dev.png", width=40, height = 25, units = "in")


################################################################################
#choropleth plot of percent in-state
state_df <- map_data("state")

choropleth <- merge(state_df, all.by.state, by = "region", all.x = T)
choropleth[with(choropleth, is.na(percent.in.state)),]$percent.in.state <- mean(choropleth$percent.in.state)
choropleth <- choropleth[order(choropleth$order), ]

steps <- seq(from = 0.0, to = 1.0, by = 0.05)

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
  custom_map_theme

ggsave("percent-in-state-choropleth-dev.png", width=40, height = 25, units = "in")

################################################################################
#choropleth plot of percent out-of-state

state_df <- map_data("state")

choropleth <- merge(state_df, all.by.state, by = "region", all.x = T)
choropleth[with(choropleth, is.na(percent.leaving.state)),]$percent.leaving.state <- mean(choropleth$percent.leaving.state)
choropleth <- choropleth[order(choropleth$order), ]

steps <- seq(from = 0.0, to = 1.0, by = 0.05)

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
  custom_map_theme

ggsave("percent-leaving-state-choropleth-dev.png", width=40, height = 25, units = "in")

################################################################################
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
