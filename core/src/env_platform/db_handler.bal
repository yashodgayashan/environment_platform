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
mongodb:Collection ministryCollection = check mongoDatabase->getCollection("ministries");
mongodb:Collection adminCollection = check mongoDatabase->getCollection("admins");
mongodb:Collection applicationMetaDataCollection = check mongoDatabase->getCollection("applicationMetaData");

# The `saveApplication` function will save the application to the applications collection in the database.
# 
# + form - Form containing the tree removal data.
# + return - Returns true if the application is saved, error if there is a mongodb:DatabaseError or  
# there's an error while generating the applicationId.
function saveApplication(TreeRemovalForm form) returns boolean|error {

    boolean result = check saveApplicationMetadata(form.title);
    log:printDebug("Saved information in application metadata: " + result.toString());
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
        if (form.status == "draft") {
            updated = applicationCollection->update({"versions.0": application}, {"applicationId": applicationId});
        } else if (form.status == "submit") {
            updated = applicationCollection->update({"versions.0": application, "status": "submit"}, {"applicationId": applicationId});
        } else {
            return error("Invalid Operation", message = "Cannot resolve the application status with the appilcation ID: "
                + applicationId + ".");
        }
    } else if (applicationStatus == "submit" && form.status == "submit") {
        map<json>[] found = check applicationCollection->find({"applicationId": applicationId});
        log:printDebug("The application of application id: " + applicationId.toString() + " is " + found.toString());

        // Get the versions array.
        int numberOfVersions = check trap <int>found[0].numberOfVersions;
        json[] versions = check trap <json[]>found[0].versions;
        versions.push(application);

        // Added new versions array to the application
        updated = applicationCollection->update({"versions": versions, numberOfVersions: numberOfVersions + 1}, {"applicationId": applicationId});
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

    map<json>[] find = check applicationMetaDataCollection->find({"applicationType": applicationType});
    map<json> applicationMetaData = check trap find[0];
    return <int>applicationMetaData.count;
}

# The `isValidUser` function will return whether the user is valid or not.
# 
# + userId - Id of the user.
# + return - This function will return either user is valid or 
# error if there is a mongodb:DatabaseError.
function isValidUser(string userId) returns boolean|error {

    int numOfDocuments = check usersCollection->countDocuments({id: userId});
    if (numOfDocuments == 1) {
        return true;
    } else {
        return numOfDocuments == 0 ? false :
            error("Cannot have duplicate User IDs", message = "There are two or more similar users in the system");
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

        // Construct the applicationList.
        json[] applicationList;
        if (applications is error) {
            applicationList = [{id: applicationId, name: applicationType}];
        } else {
            applicationList = <json[]>applications;
            log:printDebug("The user with the user ID: " + userId + " has " + applicationList.length().toString() + " applications stored in the database.");
            applicationList.push(<json>{id: applicationId, name: applicationType});
        }

        // Update the user applications array with incoming value.
        int updated = check usersCollection->update({"applications": applicationList}, {id: userId});
        log:printDebug("Updated application list for user " + userId + ": " + applicationList.toString());

        return updated > 0 ? true : false;
    } else {
        return error("Invalid User", message = "Couldn't find the user with given User ID");
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

        if (applications is error) {
            log:printDebug("The error occured is: " + applications.toString());
            return error("No applications", message = "There are no applications for the user: " + userId + ".");
        } else {
            // Convert json to json array.
            json[] applicationArray = <json[]>applications;
            log:printDebug("The user with the user ID: " + userId + " has " + applicationArray.length().toString() + " applications stored in the database.");

            // Remove the application metadata.
            json[] alteredApplicationList = [];
            applicationArray.forEach(function (json value) {
                if (value.id != applicationId) {
                    alteredApplicationList.push(value);
                }
            });

            // Update the user collection.
            int updated = check usersCollection->update({"applications": alteredApplicationList}, {id: userId});
            log:printDebug("Updated application list for user " + userId + ": " + alteredApplicationList.toString());
            return updated > 0 ? true : false;
        }
    } else {
        return error("Invalid User", message = "Couldn't find the user with given User ID");
    }
}

# The `saveApplicationMetadata` function will save application metadata to the database.
# 
# + applicationType - Type of the application.
# + return - This function will return either whether the application meta data is added or 
# error if there is a mongodb:DatabaseError.
function saveApplicationMetadata(string applicationType) returns boolean|error {
    map<json>[] find = check applicationMetaDataCollection->find({"applicationType": applicationType});

    // If a new entry
    if (find.length() == 0) {
        () insert = check applicationMetaDataCollection->insert({"applicationType": applicationType, "count": 1});
        return true;
    } else {
        map<json> applicationMetaData = find[0];
        int applicationCount = check trap <int>applicationMetaData.count + 1;

        // Update the count by one
        int update = check applicationMetaDataCollection->update({"count": applicationCount}, {"applicationType": applicationType});
        return update > 0 ? true : false;
    }
}

# The `assignMinistry` function will assign a ministry to an application.
# 
# + assignedMinistry - AssignedMinistry record which should be assigned.
# + applicationId - Application ID of the application.
# + return - This function will return whether the ministry is assigned or error if any occurs.
function assignMinistry(AssignedMinistry assignedMinistry, string applicationId) returns boolean|error {

    map<json>[] find = check applicationCollection->find({"applicationId": applicationId});

    // If no application is found.
    if (find.length() == 0) {
        return error("Invalid application", message = "There is no application with application ID: " + applicationId + ".");
    } else if (find.length() > 1) {
        return error("Invalid applicationID", message = "There is more applications with application ID: " + applicationId + ".");
    } else {
        string ministryId = assignedMinistry.ministry.id;

        // Check the validity of the ministry.
        boolean isMinist = check isMinistry(ministryId);
        if (isMinist) {
            map<json> application = find[0];
            // Get the assignments.
            json[]|error assignments = trap <json[]>application.assignments;
            int updated;
            if (assignments is error) {

                // Construct the assignment and update.
                json data = check constructAssignment(assignedMinistry);
                updated = check applicationCollection->update({assignments: [data]}, {"applicationId": applicationId});
            } else {

                // Append the new assignment to the array and updated
                json constructAssignmentArrayResult = check constructAssignmentArray(assignedMinistry, assignments);
                updated = check applicationCollection->update({assignments: assignments}, {"applicationId": applicationId});
            }
            if (updated == 1) {
                return true;
            } else {
                return false;
            }
        } else {
            return error("Invalid Operation", message = "There is no ministry found with the ID: " + ministryId + ".");
        }
    }
}

# The `isMinistry` function check whether the given ministry is available.
# 
# + ministryId - ID of the ministry.
# + return - This function either return ministry is availbale or error if there is 
# a mongodb:DatabaseError. 
function isMinistry(string ministryId) returns boolean|error {
    map<json>[] found = check ministryCollection->find({"id": ministryId});
    if (found.length() == 0) {
        return false;
    } else if (found.length() == 1) {
        return true;
    } else {
        return error("Duplicate Ids", message = "There are multiple ministries for the ID: " + ministryId + ".");
    }
}
