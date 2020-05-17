import ballerina/config as conf;
import ballerina/log;
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
mongodb:Collection usersCollection = check mongoDatabase->getCollection("users");

# The `saveApplication` function will save the application to the applications collection in the database.
# 
# + form - Form containing the tree removal data.
# + return - Returns true if the application is saved, error if there is a mongodb:DatabaseError or  
# there's an error while generating the applicationId.
function saveApplication(TreeRemovalForm form) returns boolean|error {

    // Construct the application.
    map<json> application = {
        "applicationId": check generateApplicationId(form.applicationCreatedDate, form.title),
        "status": form.status,
        "numberOfVersions": 1,
        "title": form.title,
        "versions": [
                {
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
                }
            ]
    };
    log:printDebug("Constructed application: " + application.toString());

    mongodb:DatabaseError? inserted = applicationCollection->insert(application);

    if (inserted is mongodb:DatabaseError) {
        log:printDebug("An error occurred while saving the application with ID: " + application.applicationId.toString() + ". " + inserted.reason().toString() + ".");
    } else {
        log:printDebug("Application with application ID: " + application.applicationId.toString() + " was saved successfully.");
    }
    return inserted is mongodb:DatabaseError ? inserted : true;
}

# The `deleteApplication` function will delete application drafts with the status "draft".
# 
# + applicationId - The Id of the application to be deleted.
# + return - Returns true if the application is deleted, false if not or else returns mongodb:DatabaseError
# array index out of bound if there are no applications with the specific application Id.
function deleteApplication(string applicationId) returns boolean|error {

    string applicationStatus = check getApplicationStatusByApplicationId(applicationId);
    if (applicationStatus == "draft") {
        int|error deleted = applicationCollection->delete({"applicationId": applicationId, "status": "draft"});
        if (deleted is int) {
            log:printDebug("Deleted application count: " + deleted.toString());
            return deleted == 1 ? true : false;
        } else {
            // Returns the error.
            log:printDebug("An error occurred while deleting the draft with the application ID: " + applicationId + ". " + deleted.reason() + ".");
            return deleted;
        }
    } else {
        log:printDebug("Cannot delete the application with application ID: " + applicationId + " since it is already submitted.");
        return error("Invalid Operation", message = "Cannot delete the application with the appilcation ID: "
            + applicationId + " since it is already submitted.");
    }
}

# The `getApplicationStatusByApplicationId` function will return the status of the application(draft or submitted).
# 
# + applicationId - The Id of the application which the status should be found for.
# + return - Returns the status of the application(draft, submitted).
function getApplicationStatusByApplicationId(string applicationId) returns string|error {

    // Get the application with application Id.
    map<json>[] find = check applicationCollection->find({"applicationId": applicationId});
    map<json>|error application = trap find[0];
    if (application is map<json>) {
        log:printDebug("Status of the application with application ID: " + applicationId + " is " + application.status.toString() + ".");
        return trap <string>application.status;
    } else {
        log:printDebug("An error occurred while retrieving the application:  " + application.toString() + ".");
        return application;
    }
}

# The `updateApplication` function will either alter the existing application draft or add a new version for an application 
# with the incoming form details.
# 
# + form - Form containing the tree removal data.
# + applicationId - The Id of the application which should be altered or versioned.
# + return - This function will return true if draft is updated or the application is versioned in the database, 
# false if not or else it returns a mongodb:Database error.
function updateApplication(TreeRemovalForm form, string applicationId) returns boolean|error {

    map<json> application = constructApplication(form);
    log:printDebug("Constructed application: " + application.toString());

    int|mongodb:DatabaseError updated;
    string applicationStatus = check getApplicationStatusByApplicationId(applicationId);

    // If the exsiting application is a draft.
    if (applicationStatus == "draft") {
        if (form.applicationType == "draft") {
            updated = applicationCollection->update({"versions.0": application}, {"applicationId": applicationId});
        } else if (form.applicationType == "submit") {
            updated = applicationCollection->update({"versions.0": application, "status": "submit"}, {"applicationId": applicationId});
        } else {
            return error("Invalid Operation", message = "Cannot resolve the application status with the appilcation ID: "
                + applicationId + ".");
        }
    } else if (applicationStatus == "submit" && form.applicationType == "submit") {
        map<json>[] found = check applicationCollection->find({"applicationId": applicationId});
        log:printDebug("The application of application id: " + applicationId.toString() + " is " + found.toString());

        // Get the versions array.
        json[] versions = <json[]>found[0].versions;
        versions.push(application);

        // Added new versions array to the application
        updated = applicationCollection->update({"versions": versions}, {"applicationId": applicationId});
    } else {
        return error("Invalid Operation", message = "Cannot resolve the application status with the appilcation ID: "
            + applicationId + ".");
    }

    if (updated is int) {
        log:printDebug("Updated status for application with application ID: " + applicationId + " is " + updated.toString() + ".");
        return updated == 1 ? true : false;
    } else {
        log:printDebug("An error occurred while updating the draft application with the application ID: " + applicationId + ". " + updated.reason().toString() + ".");
        return updated;
    }
}

# The `getApplicationCountByTitle` function will return the number of application for a given application type.
# 
# + applicationType - Type of the application.
# + return - This function will return either number of application with the given application type or 
# error if there is a mongodb:DatabaseError.
function getApplicationCountByTitle(string applicationType) returns int|error {
    return applicationCollection->countDocuments({"title": applicationType});
}

# The `isValidUser` function will return whether the user is valid or not.
# 
# + userId - Id of the user.
# + return - This function will return either user is valid or 
# error if there is a mongodb:DatabaseError.
function isValidUser(string userId) returns boolean|error {

    int numOfDocuments = check usersCollection->numOfDocuments({id: userId});
    if (numOfDocuments == 1) {
        return true;
    } else if (countDocuments == 0) {
        return false;
    } else {
        return error("Issue having duplicate user Ids", message = "There are two or more similar user Ids in the system");
    }
}

# The `saveApplicationInUser` function will save the application reference in the corresponding user.
# 
# + userId - Id of the user.
# + applicationId - Id of the application saved.
# + applicationType - Type of the application.
# + return - This function will return either application is saved in the given user document or 
# error if there is a mongodb:DatabaseError.
function saveApplicationInUser(string userId, string applicationId, string applicationType) returns boolean|error {

    boolean isValid = check isValidUser(userId);
    if (isValid) {

        // Get the user information.
        map<json>[] find = check usersCollection->find({id: userId});
        json|error applications = find[0].applications;
        log:printDebug("User applications are " + applications.toString());

        // Construct the applicationList.
        json[] applicationList;
        if (applications is error) {
            applicationList = [{id: applicationId, name: applicationType}];
        } else {
            applicationList = <json[]>applications;
            applicationList.push(<json>{id: applicationId, name: applicationType});
        }

        // Update the user applications array with incoming value.
        int updated = check usersCollection->update({"applications": applicationList}, {id: userId});
        log:printDebug("Updated application list is: " + applicationList.toString());
        if (updated > 0) {
            return true;
        } else {
            return false;
        }
    } else {
        return error("Invalid user", message = "Couldn't find the user with given userId");
    }
}

# The `removeApplicationInUser` function will remove the application reference in the corresponding user.
# 
# + userId - Id of the user.
# + applicationId - Id of the application which should be removed.
# + return - This function will return either application is removed in the given user document or 
# error if there is a mongodb:DatabaseError.
function removeApplicationInUser(string userId, string applicationId) returns boolean|error {
    boolean isValid = check isValidUser(userId);
    if (isValid) {

        // Get the user information.
        map<json>[] find = check usersCollection->find({id: userId});
        json|error applications = find[0].applications;
        log:printDebug("User applications are " + applications.toString());

        if (applications is error) {
            return error("No applications", message = "There are no applications for the user: " + userId + ".");
        } else {
            json[] applicationArray = <json[]>applications;
            json[] alteredApplicationList = [];
            applicationArray.forEach(function (json value) {
                if (value.id != applicationId) {
                    alteredApplicationList.push(value);
                }
            });
            int updated = check usersCollection->update({"applications": alteredApplicationList}, {id: userId});
            log:printDebug("Updated application list is: " + alteredApplicationList.toString());
            if (updated > 0) {
                return true;
            } else {
                return false;
            }
        }
    } else {
        return error("Invalid user", message = "Couldn't find the user with given userId");
    }
}
