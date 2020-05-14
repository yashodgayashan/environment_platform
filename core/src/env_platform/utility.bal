# The `extractAreaAsJSONArray` function will extract a JSON array 
# indicating the area using given locations array.
# 
# + locations - Array of location objects.
# + return - Returns the extracted JSON array which indicates the area.
function extractAreaAsJSONArray(Location[] locations) returns json[] {

    json[] area = [];
    foreach Location location in locations {
        area.push(<json>{
            "Latitude": location.latitude,
            "longitude": location.longitude
        });
    }
    return area;
}

# The `extractTreeInformationAsJSONArray` function will extract a JSON array 
# indicating information about the tree using given treeInfoArray array.
# 
# + treeInfoArray - Array of TreeInformation objects.
# + return - Returns the extracted JSON array which indicates the information 
# of the tree.
function extractTreeInformationAsJSONArray(TreeInformation[] treeInfoArray) returns json[] {

    json[] treeInformation = [];
    foreach TreeInformation treeInfo in treeInfoArray {

        // Extract the information about the tree log.
        json[] logDetails = [];
        foreach var item in treeInfo.logDetails {
            logDetails.push(<json>{
                "minGirth": item.minGirth,
                "maxGirth": item.maxGirth,
                "height": item.height
            });
        }

        // Extract other information about the tree.
        treeInformation.push(<json>{
            "species": treeInfo.species,
            "treeNumber": treeInfo.treeNumber,
            "heightType": treeInfo.heightType,
            "height": treeInfo.height,
            "girth": treeInfo.girth,
            "logDetails": logDetails
        });
    }
    return treeInformation;
}
