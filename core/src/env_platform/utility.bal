import ballerina/time;
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

# The `constructApplication` function will construct the application which will be suitable for the database.
# 
# + form - Form containing the tree removal data.
# + return - Returns a map<json> containing the application structure which suites the database.
function constructApplication(TreeRemovalForm form) returns map<json> {
    return {
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

# The `generateApplicationId` function will return a unique Id for a given application type. 
# The format is <applicationCode>-<createdDate>-<applicationNumber>.
# 
# + createdDate - Created date of the application.
# + applicationType -  Application type of the application.
# + return - Returns a unique application Id or corresponding error.
function generateApplicationId(Date createdDate, string applicationType) returns string|error {

    // Get the application code
    string applicationCode = check getApplicationCode(applicationType);

    // Convert the createdDate to a formatted string
    time:Time timeCreated = check time:createTime(createdDate.year, createdDate.month, createdDate.day, 0, 0, 0, 0, "Asia/Colombo");
    string customTimeString = check time:format(timeCreated, "yyyyMMdd");

    // Get application count
    int applicationCount = (check getApplicationCountByTitle(applicationType) + 1);
    return applicationCode + "-" + customTimeString + "-" + applicationCount.toString();
}


# The `getApplicationCode` function will return the corresponding application code for a given application type.
# 
# + applicationType - Application type of the application.
# + return - Returns the application code or an error if the application type is mot identified.
function getApplicationCode(string applicationType) returns string|error {
    if (applicationType == "tree removal form") {
        return "trf";
    } else {
        return error("Unknown application type", message = "Unknown application type: " + applicationType + ".");
    }
}
