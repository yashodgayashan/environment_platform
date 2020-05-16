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

# The `constructApplicationVersion` function will construct the application version which will be suitable for the database.
# 
# + form - TreeRemovalForm type record.
# + return - Returns the map<json> which suites for the database
function constructApplicationVersion(TreeRemovalForm form) returns map<json> {
    return {
        "title": form.title,
        "applicationCreatedDate": {
            "year": form.applicationCreatedDate.year,
            "month": form.applicationCreatedDate.month,
            "day": form.applicationCreatedDate.day,
            "hour": form.applicationCreatedDate.hour,
            "minute": form.applicationCreatedDate.minute
        },
        "removalDate": {
            "year": form.removalDate.year,
            "month": form.removalDate.month,
            "day": form.removalDate.day,
            "hour": form.removalDate.hour,
            "minute": form.removalDate.minute
        },
        "reason": form.reason,
        "applicationType": form.applicationType,
        "requestedBy": form.requestedBy,
        "permitRequired": form.permitRequired,
        "landOwner": form.landOwner,
        "treeRemovalAuthority": form.treeRemovalAuthority,
        "city": form.city,
        "district": form.district,
        "nameOfTheLand": form.nameOfTheLand,
        "planNumber": form.planNumber,
        "area": extractAreaAsJSONArray(form.area),
        "treeInformation": extractTreeInformationAsJSONArray(form.treeInformation)
    };
}
