import ballerina/config as conf;
import ballerina/mongodb;

// Mongodb configurations.
mongodb:ClientConfig mongoConfig = {
    host: conf:getAsString("DB_HOST"),
    username: conf:getAsString("DB_USER_NAME"),
    password: conf:getAsString("DB_PASSWORD"),
    options: {sslEnabled: false, serverSelectionTimeout: 500}
};
mongodb:Client mongoClient = check new (mongoConfig);
mongodb:Database mongoDatabase = check mongoClient->getDatabase("EnvironmentPlatform");
mongodb:Collection applicationCollection = check mongoDatabase->getCollection("applications");

# The `postApplicationToDB` function will post the application to the applications collection in the database.
# 
# + form - The TreeRemovalForm Type record is accepted.
# 
# + return - This function will return null if application is added to the database or else return mongodb:Database error
function postApplicationToDB(TreeRemovalForm form) returns error? {

    json[] locations = [];
    foreach Location location in form.area {
        locations.push(<json>{"Latitude": location.latitude, "longitude": location.longitude});
    }
    json[] treeInformation = [];
    foreach TreeInformation treeInfo in form.treeInformation {
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
    map<json> application = {
        "applicationId": "tcf-20200513",
        "status": form.status,
        "numberOfVersions": 1,
        "versions": [
                {
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
                    "area": locations,
                    "treeInformation": treeInformation
                }
            ]
    };
    return applicationCollection->insert(application);
}
