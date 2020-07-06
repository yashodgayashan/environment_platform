import config_handler;
import ballerina/log;
import ballerina/mongodb;

mongodb:Collection applicationCollection = config_handler:getApplicationCollection();
mongodb:Collection applicationMetaDataCollection = config_handler:getApplicationMetadataCollection();
mongodb:Collection ministryCollection = config_handler:getMinistryCollection();
mongodb:Collection userCollection = config_handler:getUserCollection();

# The `saveApplication` function will save the application to the applications collection in the database.
# 
# + form - Form containing the tree removal data.
# + userId - Id of the User. 
# + return - Returns [true, applicationId] if the application is saved, error if there is a mongodb:DatabaseError or  
# a problem occurs while generating the applicationId.
function saveApplication(TreeRemovalForm form, string userId) returns [boolean, string]|error {

    if (check isValidUser(userId)) {
        string applicationId = check generateApplicationId(form.applicationCreatedDate, form.title);

        // Added form information to metadata.
        boolean result = check saveApplicationMetadata(form.title);
        log:printDebug("Saved information in application metadata? => " + result.toString());

        // Add the form application ID to the user.
        boolean saveApplicationInUserResult = check saveApplicationInUser(userId, applicationId, form.title);
        log:printDebug("Saved information in users account? => " + saveApplicationInUserResult.toString());

        // Construct the application.
        map<json> application = {
            "applicationId": applicationId,
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
        log:printDebug("Constructed application with application ID: " + application.applicationId.toString());

        mongodb:DatabaseError? inserted = applicationCollection->insert(application);

        if (inserted is mongodb:DatabaseError) {
            log:printDebug("An error occurred while saving the application with ID: " + application.applicationId.toString() + ". Reason: " + inserted.reason().toString() + ".");
        } else {
            log:printDebug("Application with application ID: " + application.applicationId.toString() + " was saved successfully.");
        }
        return inserted is mongodb:DatabaseError ? inserted : [true, applicationId];
    } else {
        return error("Invalid User", message = "Couldn't find a user with given User ID.");
    }
}

# The `deleteDraftApplication` function will delete application drafts with the status "draft".
# 
# + applicationId - The Id of the application to be deleted.
# + userId - Id of the User. 
# + return - Returns true if the application is deleted, false if not or else returns mongodb:DatabaseError
# array index out of bound if there are no applications with the specific application Id.
function deleteDraftApplication(string applicationId, string userId) returns boolean|error {

    string applicationStatus = check getApplicationStatusByApplicationId(applicationId);
    if (applicationStatus == "draft") {
        // Delete the specified application from the applications collection.
        int|error deleted = applicationCollection->delete({"applicationId": applicationId, "status": "draft"});
        if (deleted is int) {
            log:printDebug("Deleted application count: " + deleted.toString());
            if (deleted == 1) {
                // Delete the specified application from the user.
                boolean removeApplicationInUserResult = check removeApplicationInUser(userId, applicationId);
                log:printDebug("Application removed from the user? => " + removeApplicationInUserResult.toString() + ".");
                return true;
            } else {
                return false;
            }
        } else {
            // Returns an error.
            log:printDebug("An error occurred while deleting the draft with the application ID: " + applicationId + ". Reason: " + deleted.reason() + ".");
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

    int numOfDocuments = check userCollection->countDocuments({id: userId});
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
        map<json>[] find = check userCollection->find({id: userId});
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
        int updated = check userCollection->update({"applications": applicationList}, {id: userId});
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
        map<json>[] find = check userCollection->find({id: userId});
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
            int updated = check userCollection->update({"applications": alteredApplicationList}, {id: userId});
            log:printDebug("Updated application list for user " + userId + ": " + alteredApplicationList.toString());
            return updated > 0 ? true : false;
        }
    } else {
        return error("Invalid User", message = "Couldn't find the user with given User ID");
    }
}

# The `applicationBelongsToUser` function will validate whether the application belongs to the user.
# 
# + applicationId - Id of the application.
# + userId - Id of the user.
# + return - This will return whether the application belongs to the user or an error.
function applicationBelongsToUser(string applicationId, string userId) returns boolean|error {
    boolean isValid = check isValidUser(userId);
    if (isValid) {

        // Get the user information.
        map<json>[] find = check userCollection->find({id: userId});
        json|error applications = find[0].applications;

        // Construct the application list.
        json[] applicationList;
        if (applications is error) {
            return error("No applications", message = "User with ID: " + userId + " doesn't have any application.");
        } else {
            applicationList = <json[]>applications;
            log:printDebug("The user with ID: " + userId + " has " + applicationList.length().toString() + " applications stored in the database.");
            foreach json application in applicationList {
                if (application.id == applicationId) {
                    return true;
                }
            }
            return false;
        }
    } else {
        return error("Invalid User", message = "Couldn't find a user with the given ID: " + userId + ".");
    }
}

# The `getApplicationTypeById` function will return the application type of a given application.
# 
# + applicationId - Id of the application.
# + return - This will return either the application title for the given user or an error.
function getApplicationTypeById(string applicationId) returns string|error {
    map<json>[] find = check applicationCollection->find({"applicationId": applicationId});
    int arrayLength = find.length();
    if (arrayLength == 0) {
        return error("Not found", message = "An application with the ID: " + applicationId + " was not found.");
    } else {
        return check trap <string>find[0].title;
    }
}

# The `saveApplicationInMinistry` function will save the application reference in the corresponding ministry.
# 
# + ministryId - Id of the ministry.
# + applicationId - Id of the application.
# + return - This will return either the application metadata if it is saved in ministry or a corresponding error.
function saveApplicationInMinistry(string ministryId, string applicationId) returns boolean|error {
    string applicationType = check getApplicationTypeById(applicationId);
    if (check isMinistry(ministryId)) {
        // Get the ministry information.
        map<json>[] find = check ministryCollection->find({id: ministryId});
        json|error applications = find[0].applications;

        // Construct the applicationList.
        json[] applicationList;
        if (applications is error) {
            applicationList = [{id: applicationId, name: applicationType}];
        } else {
            applicationList = <json[]>applications;
            log:printDebug("The ministry with the ID: " + ministryId + " has " + applicationList.length().toString() + " applications stored in the database.");
            applicationList.push(<json>{id: applicationId, name: applicationType});
        }

        // Update the user applications array with incoming value.
        int updated = check ministryCollection->update({"applications": applicationList}, {id: ministryId});
        log:printDebug("Updated application list for Ministry ID: " + ministryId + ". Added application with ID: " + applicationId + ".");

        return updated > 0 ? true : false;
    } else {
        return error("Invalid Ministry", message = "Couldn't find a ministry with the given ID: " + ministryId + ".");
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

# The `removeApplicationMetadata` function will subtract application metadata count by one from the database.
# 
# + applicationType - Type of the application.
# + return - This function will return either whether the application meta data count is updated or 
# error if there is a mongodb:DatabaseError.
function removeApplicationMetadata(string applicationType) returns boolean|error {
    map<json>[] find = check applicationMetaDataCollection->find({"applicationType": applicationType});

    map<json> applicationMetaData = find[0];
    int applicationCount = check trap <int>applicationMetaData.count - 1;

    // Update the count by minus one.
    int update = check applicationMetaDataCollection->update({"count": applicationCount}, {"applicationType": applicationType});
    return update > 0 ? true : false;
}

# The `assignMinistry` function will assign a ministry to an application.
# 
# + assignedMinistry - AssignedMinistry record which should be assigned.
# + applicationId - Application ID of the application.
# + adminId - Id of the assigned administrator.
# + return - This function will return whether the ministry is assigned or error if any occurs.
function assignMinistry(AssignedMinistry assignedMinistry, string applicationId, string adminId) returns boolean|error {

    map<json>[] find = check applicationCollection->find({"applicationId": applicationId, status: "submit"});

    // If no application is found or if the application is still a draft.
    if (find.length() == 0) {
        return error("Invalid application", message = "There is no application with application ID: " + applicationId + ".");
    } else if (find.length() > 1) {
        return error("Invalid application", message = "There are one or more applications with the application ID: " + applicationId + ".");
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
                json data = check constructAssignment(assignedMinistry, adminId);
                updated = check applicationCollection->update({assignments: [data]}, {"applicationId": applicationId});
            } else {

                // Append the new assignment to the array and update.
                json constructAssignmentArrayResult = check constructAssignmentArray(assignedMinistry, adminId, assignments);
                updated = check applicationCollection->update({assignments: assignments}, {"applicationId": applicationId});
            }
            if (updated == 1) {
                // Save application metadata in ministry.
                boolean saveApplicationInMinistryResult = check saveApplicationInMinistry(ministryId, applicationId);
                saveApplicationInMinistryResult ? return true:false;
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
    if (found.length() > 1) {
        return error("Duplicate ID", message = "There are multiple ministries for the ID: " + ministryId + ".");
    } else {
        return found.length() == 1 ? true : false;
    }
}

# The `updateStatus` function will create a new version of the status and push it to the status array of the appropriate assignment 
# in the assignments array.
# 
# + status - Incoming status for the application.
# + applicationId - Application Id of the application.
# + return - This function will return either the updated status or appropriate error.
function updateStatus(Status status, string applicationId) returns boolean|error {
    map<json>[] applications = check applicationCollection->find({"applicationId": applicationId, status: "submit"});

    // If no application is found or if the application is still a draft.
    if (applications.length() == 0) {
        return error("Not found", message = "Application with application ID: " + applicationId + " is not found.");
    } else {
        map<json> application = check trap <map<json>>applications[0];
        json[]|error assignments = trap <json[]>application.assignments;
        if (assignments is json[]) {
            [boolean, json?, boolean, boolean] [isMinistryAssigned, assignment, hasPrerequisite, isPrerequisiteCompeted] = check getAssignedMinistryInfo(assignments, status.ministry.id);
            if (isMinistryAssigned) {
                if (!hasPrerequisite || (hasPrerequisite && isPrerequisiteCompeted)) {
                    // Update the assignment with new status.
                    json updatedAssignment = check updateAssignment(assignment, status);
                    // Update the assignments array.
                    check updateAssignments(assignments, updatedAssignment, status.ministry.id);
                    int updated = check applicationCollection->update({assignments: assignments}, {"applicationId": applicationId});
                    return updated == 1 ? true : false;
                } else {
                    return error("Prerequisite Ministry approval pending", message = "Prerequisite ministry has not completed processing the application.");
                }
            } else {
                return error("Ministry not assigned", message = status.ministry.name + " is not assigned to application with application Id: " + applicationId + ".");
            }
        } else {
            return error("Ministry not assigned", message = status.ministry.name + " is not assigned to application with application Id: " + applicationId + ".");
        }
    }
}

# The `isMinistryHasUser` function will check the corresponding user is in the ministry.
# 
# + ministryId - Id of the ministry.
# + userId - Id of the user.
# + return - This function will either ministru has corresponding user or an error.
function isMinistryHasUser(string ministryId, string userId) returns boolean|error {

    // Get ministry information.
    map<json>[] find = check ministryCollection->find({id: ministryId});
    int arrayLength = find.length();
    if (arrayLength == 0) {
        return error("Not found", message = "Ministry with the ID: " + ministryId + " was not found.");
    } else {
        map<json> ministry = find[0];
        json[] users = check trap <json[]>ministry.users;
        foreach json user in users {
            if (user.id == userId) {
                return true;
            }
        }
        return false;
    }
}
