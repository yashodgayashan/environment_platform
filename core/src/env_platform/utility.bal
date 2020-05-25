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
    int applicationCount = check getApplicationCountByTitle(applicationType);
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

# The `getCurrentDateObject` function will return a current time as a date object.
# 
# + return - This function returns a Date object.
function getCurrentDateObject() returns Date {
    time:Time time = time:currentTime();
    return {
        "year": time:getYear(time),
        "month": time:getMonth(time),
        "day": time:getDay(time),
        "hour": time:getHour(time),
        "minute": time:getMinute(time)
    };
}

# The `constructAssignment` function will construct the assignment from the given AssignedMinistry record.
# 
# + assignedMinistry - AssignedMinistry record.
# + return - This function will return a assignment json or an error if the Data record is not converted to the json, 
# Mongodb:DatabaseError or prerequisite ministry is not found.
function constructAssignment(AssignedMinistry assignedMinistry) returns json|error {

    json data;
    Ministry? prerequisite = assignedMinistry?.prerequisite;

    // If prerequisite is available.
    if (prerequisite is Ministry) {

        // Check the prerequisite ministry availablity.
        if (check isMinistry(prerequisite.id)) {
            data = {
                id: assignedMinistry.ministry.id,
                name: assignedMinistry.ministry.name,
                prerequisiteId: prerequisite.id,
                prerequisiteName: prerequisite.name,
                status: [
                        {
                            progress: "New",
                            timestamp: check json.constructFrom(getCurrentDateObject())
                        }
                    ]
            };
        } else {
            return error("Invalid Operation", message = "There is no prerequisite ministry found with the ID: " + prerequisite.id + ".");
        }
    } else {
        data = {
            id: assignedMinistry.ministry.id,
            name: assignedMinistry.ministry.name,
            status: [
                    {
                        progress: "New",
                        timestamp: check json.constructFrom(getCurrentDateObject())
                    }
                ]
        };
    }
    return data;
}

# The `constructAssignmentArray` function will construct the assignments array by pushing the new assigned ministry.
# 
# + assignedMinistry - AssignedMinistry record which must be add to the assignments.
# + assignments - All the assignments of an application.
# + return - This function will return either constructed assigned ministry array or an error.
function constructAssignmentArray(AssignedMinistry assignedMinistry, json[] assignments) returns json|error {

    error duplicateError = error("Ministry already assigned", message = "Ministry with the ID: " + assignedMinistry.ministry.id + " is already assigned");
    boolean isError = false;

    // Check if the ministry is already assigned.
    foreach json assignment in assignments {
        map<json> assignmentMap = <map<json>>assignment;
        if (assignmentMap.id == assignedMinistry.ministry.id) {
            isError = true;
            break;
        }
    }

    if (isError) {
        return duplicateError;
    } else {
        assignments.push(check constructAssignment(assignedMinistry));
        return assignments;
    }
}

# The `getAssignedMinistryInfo` function will output the given ministry information.
# 
# + assignments - Assignment information of an application;
# + ministryId - Id of the assigned ministry. 
# + return - This function will return whether ministry is assigned to the application, assignment if ministry is assigned,
# whether ministry has prerequisite, whether prerequisite is completed or an appropriate error.
function getAssignedMinistryInfo(json[] assignments, string ministryId) returns [boolean, json?, boolean, boolean]|error {

    boolean isMinistryAssigned = false;
    json? assignmentInfo = ();
    boolean hasPrerequisite = false;
    boolean isPrerequisiteCompeted = false;

    foreach json assignment in assignments {
        if (check trap <string>assignment.id == ministryId) {
            isMinistryAssigned = true;
            assignmentInfo = assignment;
            string|error prerequisiteId = trap <string>assignment.prerequisiteId;
            if (prerequisiteId is string) {
                hasPrerequisite = true;
                isPrerequisiteCompeted = check isMinistryCompleted(assignments, prerequisiteId);
            }
            break;
        }
    }
    return [isMinistryAssigned, assignmentInfo, hasPrerequisite, isPrerequisiteCompeted];
}

# The `isMinistryCompleted` function will return whether a particular ministry has completed processing the application.
# 
# + assignments - All the assignments of the application.
# + ministryId - Id of the ministry.
# + return - This will return whether ministry has completed processing or data type conversion errors.
function isMinistryCompleted(json[] assignments, string ministryId) returns boolean|error {
    foreach json assignment in assignments {
        if (check trap <string>assignment.id == ministryId) {
            json[] status = check trap <json[]>assignment.status;
            string progress = check trap <string>status[status.length() - 1].progress;
            if (progress == "Completed") {
                return true;
            }
            break;
        }
    }
    return false;
}

# The `updateAssignment` function will push the incoming status to the status array of the assignment.
# 
# + assignment - Single ministry assignment.
# + status - Incomming status.
# + return - This function will return updated assignment or an error if occurred.
function updateAssignment(json assignment, Status status) returns json|error {
    map<json> assignmentInfo = check trap <map<json>>assignment;
    json[] statusArray = check trap <json[]>assignmentInfo.status;
    statusArray.push(check constructStatus(status));
    return assignmentInfo;
}

# The `constructStatus` function will construct the given status to an appropriate format.
# 
# + status - Status which should be formatted.
# + return - This function will return either formatted json or an appropriate error.
function constructStatus(Status status) returns json|error {
    if (status?.reason is ()) {
        return {
            progress: status.progress,
            changedBy: check json.constructFrom(status.changedBy),
            timestamp: check json.constructFrom(status.timestamp)
        };
    } else {
        return {
            progress: status.progress,
            changedBy: check json.constructFrom(status.changedBy),
            timestamp: check json.constructFrom(status.timestamp),
            reason: status?.reason
        };
    }
}

# The `updateAssignments` function will updated the assignment array with updated assignment.
# 
# + assignments - Array of assignments of the application.
# + updatedAssignment - Assignment which is updated with incoming status.
# + ministryId - Id of the ministry which assignment should be altered.
# + return - This function will return null or not exist error.
function updateAssignments(json[] assignments, json updatedAssignment, string ministryId) returns error?{
    int id = 0;
    foreach json assignment in assignments{
        if(check trap assignment.id==ministryId){
            assignments[id] = updatedAssignment;
            break;
        }
        id = id + 1;
    }
}
