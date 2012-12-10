library(ggplot2)
library(maps)
library(geosphere)

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
referrer.data <- read.csv("refer.2011.sample.csv", header=F)
colnames(referrer.data) <- c("doc1", "doc2", "number.of.patients")

interm.join <- merge(referrer.data, npi.to.location, by.x = "doc1", by.y = "npi_number")
doc.with.location <- merge(interm.join, npi.to.location, by.x = "doc2", by.y = "npi_number")
interm.join <- NULL #Null out reference to save memory


doc.with.location$distance <- earth.dist(doc.with.location$long.x, 
                                         doc.with.location$lat.x, 
                                         doc.with.location$long.y, 
                                         doc.with.location$lat.y)

doc.with.location <- doc.with.location[with(doc.with.location, order(-distance)),]
#Remove connects that are to close together to see on a large map
docs.with.geographic.distance <- subset(doc.with.location, distance > 100)

# only use a sample of the total connections to make iterating on UI easier
#docs.with.geographic.distance <- docs.with.geographic.distance[sample(1:nrow(docs.with.geographic.distance), 5000, replace=F),]
docs.with.geographic.distance$index <- 1:nrow(docs.with.geographic.distance)


png("./map-of-connections.png", height=9216, width=16384)

#Draw the base Map
xlim <- c(-171.738281, -56.601563)
ylim <- c(12.039321, 71.856229)

map("world", col="black", fill=FALSE, bg="black", lwd=0.01, xlim=xlim, ylim=ylim)

#Setup color scheme
#pallet <- colorRampPalette(c("#0087E1", "#6AC4FF")) #Blue colorscheme 
pallet <- colorRampPalette(c("#5B030B", "#E00619")) # Dark red colorscheme
#pallet <- colorRampPalette(c("#840410", "#F70D23")) # Lighter red color scheme
bin.width <- 1000
colors <- pallet(ceiling(nrow(docs.with.geographic.distance) / bin.width))

#Draw the connections
apply(docs.with.geographic.distance, 1, function(row) {
        inter <- gcIntermediate(c(row[["long.x"]], row[["lat.x"]]), 
                                c(row[["long.y"]], row[["lat.y"]]),
                                n=50,
                                addStartEnd=TRUE)
        if(!row[["long.x"]] > xlim[2] && !row[["long.y"]] > xlim[2]){
          color = colors[ceiling(row[["index"]] / bin.width)]
          lines(inter, col = color, lwd = 0.8)
        }
     })

#Render image to PDF
dev.off()
