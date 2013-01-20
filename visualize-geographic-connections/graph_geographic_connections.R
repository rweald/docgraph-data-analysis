library(ggplot2)
library(maps)
library(geosphere)
library(plyr)

# This function is curtosy of
# http://menugget.blogspot.com/2011/05/r-functions-for-earth-geographic_29.html
earth.dist <- function (long1, lat1, long2, lat2) {
  rad <- pi/180
  a1 <- lat1 * rad
  a2 <- long1 * rad
  b1 <- lat2 * rad
  b2 <- long2 * rad
  dlon <- b2 - a2
  dlat <- b1 - a1
  a <- (sin(dlat/2))^2 + cos(a1) * cos(b1) * (sin(dlon/2))^2
  c <- 2 * atan2(sqrt(a), sqrt(1 - a))
  R <- 6378.145
  d <- R * c
  return(d)
}

npi.to.location <- read.csv("npi_to_location.csv")
referrer.data <- read.csv("refer.2011.sample2.csv", header=F)
colnames(referrer.data) <- c("doc1", "doc2", "number.of.patients")

interm.join <- merge(referrer.data, npi.to.location, by.x = "doc1", by.y = "npi_number")
doc.with.location <- merge(interm.join, npi.to.location, by.x = "doc2", by.y = "npi_number")
interm.join <- NULL #Null out reference to save memory


doc.with.location$distance <- earth.dist(doc.with.location$long.x, 
                                         doc.with.location$lat.x, 
                                         doc.with.location$long.y, 
                                         doc.with.location$lat.y)

doc.with.location <- doc.with.location[with(doc.with.location, order(-distance)),]

#Remove connects that are t0o close together to see on a large map
doctor.connections <- subset(doc.with.location, distance > 100)

# While iterating on UI use only a sample of the connections
#doctor.connections <- doctor.connections[sample(1:nrow(doctor.connections), 100000, replace=F),]

doctor.connections$index <- 1:nrow(doctor.connections)


png("./map-of-connections-dev.png", width=9600, height=5400)
par(mar=c(5,3,2,2)+0.1)

#Draw the base Map
x_limit <- c(-171.738281, -56.601563)
y_limit <- c(12.039321, 71.856229)

map("state", col="black", fill=FALSE, bg="black", lwd=0.01)

#Setup color scheme
pallet <- colorRampPalette(c("#5B030B", "#E00619")) # Dark red colorscheme
bin.width <- 1000
colors <- pallet(ceiling(nrow(doctor.connections) / bin.width))

#Draw the connections
apply(doctor.connections, 1, function(row) {
        inter <- gcIntermediate(c(row[["long.x"]], row[["lat.x"]]), 
                                c(row[["long.y"]], row[["lat.y"]]),
                                n=50,
                                addStartEnd=TRUE)

        # Remove connections outside scope of graph.
        # These connections create annoying horizontal lines and weren't 
        # worth the time to wrap around the edges
        if(!row[["long.x"]] > x_limit[2] && !row[["long.y"]] > x_limit[2]){
          color = colors[ceiling(row[["index"]] / bin.width)]
          segment.color.gradient <- colorRampPalette(c(color, "#103074"))(50)
          s <- seq(length(inter[,"lon"]) - 1)
          segments(inter[s,"lon"], inter[s, "lat"], inter[s+1, "lon"], inter[s+1, "lat"], col = segment.color.gradient, lwd = 0.8)
        }
     })

#Render image
dev.off()
