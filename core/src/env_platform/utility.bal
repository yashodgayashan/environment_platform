# The `getAreaJsonArray` function will construct the area json array using given Location array.
# 
# + locations - Array of location objects.
# + return - Returns the constructed json array of locations.
function getAreaJsonArray(Location[] locations) returns json[] {
    json[] area = [];
    foreach Location location in locations {
        area.push(<json>{"Latitude": location.latitude, "longitude": location.longitude});
    }
    return area;
}

function getTreeInformationJsonArray(TreeInformation[] treeInfor) returns json[] {
    json[] treeInformation = [];
    foreach TreeInformation treeInfo in treeInfor {
        json[] logDetails = [];
        foreach var item in treeInfo.logDetails {
            logDetails.push(<json>{"minGirth": item.minGirth, "maxGirth": item.maxGirth, "height": item.height});
        }
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
