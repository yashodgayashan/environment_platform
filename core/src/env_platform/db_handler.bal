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

# The `saveApplication` function will post the application to the applications collection in the database.
# 
# + form - The TreeRemovalForm Type record is accepted.
# + return - This function will return null if application is added to the database or else return mongodb:Database error.
function saveApplication(TreeRemovalForm form) returns error? {

    // Construct the application.
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
                    "area": getAreaJsonArray(form.area),
                    "treeInformation": getTreeInformationJsonArray(form.treeInformation)
                }
            ]
    };
    return applicationCollection->insert(application);
}

# The `deleteApplication` function will delete application drafts where status is set to "save".
# 
# + applicationId - The Id of the application which must be deleted
# + return - This function will return null if application is deleted from the database or else return mongodb:DatabaseError
# array index out of bound if there are no application with the specific application Id.
function deleteApplication(string applicationId) returns boolean|error {

    string applicationType = check getApplicationTypeByApplicationId(applicationId);
    if (applicationType == "save") {
        int delete = check applicationCollection->delete({"applicationId": applicationId, "status": "save"});
        return true;
    } else {
        return error("Invalid Operation", message = "Cannot remove submitted application");
    }
}

# The `getApplicationTypeByApplicationId` function will output whether the application is save or submit.
# 
# + applicationId - The Id of the application which must be deleted
# + return - This function will return string "save" if the application is a draft or "submit" if the application is 
# submitted or error if any occured.
function getApplicationTypeByApplicationId(string applicationId) returns string|error {

    // Get the application with application Id
    map<json>[] find = check applicationCollection->find({"applicationId": applicationId});

    map<json>|error application = trap find[0];
    if (application is map<json>) {
        return trap <string>application.status;
    } else {
        return application;
    }
}
