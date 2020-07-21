import ballerina/config as conf;
import ballerina/http;
import ballerina/jwt;
import ballerina/log;
import ballerina/openapi;

jwt:InboundJwtAuthProvider jwtAuthProvider = new ({
    issuer: "environment platform",
    trustStoreConfig: {
        certificateAlias: "ballerina",
        trustStore: {
            path: conf:getAsString("TRUST_STORE_PATH"),
            password: conf:getAsString("TRUST_STORE_PASSWORD")
        }
    }
});

http:BearerAuthHandler jwtAuthHandler = new (jwtAuthProvider);

listener http:Listener ep0 = new (9090, config = {
    auth: {
        authHandlers: [jwtAuthHandler]
    },

    secureSocket: {
        keyStore: {
            path: conf:getAsString("KEY_STORE_PATH"),
            password: conf:getAsString("KEY_STORE_PASSWORD")
        }
    }
});

@openapi:ServiceInfo {
    contract: "resources/openapi_v3.yaml"
}
@http:ServiceConfig {
    basePath: "/",
    cors: {
        allowOrigins: ["*"]
    }
}

service envservice on ep0 {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/applications"
    }
    resource function getApplications(http:Caller caller, http:Request req) returns error? {

    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/applications",
        consumes: ["application/json"],
        body: "body",
        auth: {
            scopes: ["User"],
            enabled: true
        }
    }
    resource function postApplication(http:Caller caller, http:Request req, TreeRemovalForm body) returns error? {

        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error userInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (userInfoFromJWT is [string, string]) {
            [string, string] [userId, userType] = userInfoFromJWT;
            log:printDebug("User information - user ID: " + userId + ", userType: " + userType + ".");
            [boolean, string]|error saveApplicationResult = saveApplication(body, userId);
            if (saveApplicationResult is error) {
                log:printDebug("Error occured is - " + saveApplicationResult.toString() + ".");
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                response.setPayload(<@untainted>{message: "Internal Server Error occurred."});
            } else {
                [boolean, string] [isSaved, applicationId] = saveApplicationResult;
                log:printDebug("Application is saved and application ID is " + applicationId + ".");
                response.statusCode = http:STATUS_CREATED;
                response.setPayload(<@untainted>{"applicationId": applicationId});
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            response.setPayload({message: "Unauthorized operation. Try again with valid credentials."});
        }
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/applications/{applicationId}"
    }
    resource function getApplicationById(http:Caller caller, http:Request req, string applicationId) returns error? {

    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/applications/{applicationId}",
        body: "body",
        auth: {
            scopes: ["User"],
            enabled: true
        }
    }
    resource function putApplicationById(http:Caller caller, http:Request req, string applicationId, TreeRemovalForm body)
    returns error? {

        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error userInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (userInfoFromJWT is [string, string]) {
            [string, string] [userId, userType] = userInfoFromJWT;
            log:printDebug("User information - user ID: " + userId + ", user type: " + userType + ".");
            boolean|error applicationBelongsToUserResult = applicationBelongsToUser(applicationId, userId);
            if (applicationBelongsToUserResult is error) {
                log:printDebug("Error occured is - " + applicationBelongsToUserResult.toString() + ".");
                response.statusCode = http:STATUS_NOT_FOUND;
                response.setPayload(<@untainted>{"reason": applicationBelongsToUserResult.reason()});
            } else {
                // If application is releated to the user.
                if (applicationBelongsToUserResult) {
                    boolean|error application = updateApplication(body, applicationId);
                    if (application is boolean && application) {
                        log:printDebug("Application is updated");
                        response.statusCode = http:STATUS_OK;
                        response.setPayload({"reason": "Application is updated."});
                    } else {
                        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                        if (application is error) {
                            log:printDebug("Error occured is: " + application.reason() + ".");
                            response.setPayload(<@untainted>{"reason": application.reason()});
                        } else {
                            log:printDebug("Application is not updated.");
                            response.setPayload({"reason": "Application is not updated."});
                        }
                    }
                } else {
                    log:printDebug(applicationId + "application does not belong to the user with user ID: " + userId + ".");
                    response.statusCode = http:STATUS_NOT_FOUND;
                    response.setPayload({"reason": "Application has not been submitted by the user."});
                }
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            response.setPayload({message: "Unauthorized operation. Try again with valid credentials."});
        }
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/applications/{applicationId}",
        auth: {
            scopes: ["User"],
            enabled: true
        }
    }
    resource function deleteApplicationById(http:Caller caller, http:Request req, string applicationId) returns error? {

        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error userInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (userInfoFromJWT is [string, string]) {
            [string, string] [userId, userType] = userInfoFromJWT;
            log:printDebug("User information - user ID: " + userId + ", user type: " + userType + ".");
            boolean|error applicationBelongsToUserResult = applicationBelongsToUser(applicationId, userId);
            if (applicationBelongsToUserResult is error) {
                log:printDebug("Error occured is: " + applicationBelongsToUserResult.reason());
                response.statusCode = http:STATUS_NOT_FOUND;
                response.setPayload(<@untainted>{"reason": applicationBelongsToUserResult.reason()});
            } else {
                boolean|error application = deleteDraftApplication(applicationId, userId);
                if (application is boolean && application) {
                    log:printDebug("Application is deleted.");
                    response.statusCode = http:STATUS_OK;
                    response.setPayload({"reason": "Application is deleted."});
                } else {
                    log:printDebug("Application is not deleted.");
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    response.setPayload({"reason": "Application is not deleted."});
                }
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            response.setPayload({message: "Unauthorized operation. Try again with valid credentials."});
        }
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/applications/{applicationId}/assign-ministry",
        body: "body",
        auth: {
            scopes: ["Admin"],
            enabled: true
        }
    }
    resource function assignMinistry(http:Caller caller, http:Request req, string applicationId, AssignedMinistry body) returns error? {

        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error adminInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (adminInfoFromJWT is [string, string]) {
            [string, string] [adminId, adminType] = adminInfoFromJWT;
            log:printDebug("User information - admin ID: " + adminId + ", admin type: " + adminType + ".");
            boolean|error assignMinistryResult = assignMinistry(body, applicationId, adminId);
            if (assignMinistryResult is boolean && assignMinistryResult) {
                log:printDebug("Successfully assigned the ministry " + body.ministry.name + " for the application with ID: "
                    + applicationId + ".");
                response.statusCode = http:STATUS_OK;
                response.setPayload({"message": "Successfully assigned the ministry."});
            } else {
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                if (assignMinistryResult is error) {
                    log:printDebug("Error occured is " + assignMinistryResult.reason() + ".");
                    response.setPayload(<@untainted>{"message": assignMinistryResult.reason()});
                } else {
                    log:printDebug("Failed to assigned the ministry.");
                    response.setPayload({"message": "Failed to assigned the ministry."});
                }
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            response.setPayload({message: "Unauthorized operation. Try again with valid credentials."});
        }
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/applications/{applicationId}/update-status",
        body: "body",
        auth: {
            scopes: ["Admin", "Ministry"],
            enabled: true
        }
    }
    resource function updateStatus(http:Caller caller, http:Request req, string applicationId, Status body) returns error? {

        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error userInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (userInfoFromJWT is [string, string]) {
            [string, string] [userId, userType] = userInfoFromJWT;
            log:printDebug("User information - user ID: " + userId + ", user type: " + userType + ".");
            if (body.changedBy.id == userId) {
                // Check whether ministry has such user.
                boolean|error isMinistryHasUserResult = isMinistryHasUser(body.ministry.id, userId);
                if (isMinistryHasUserResult is error) {
                    log:printDebug("Error occured is : " + isMinistryHasUserResult.reason() + ".");
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    response.setPayload(<@untainted>{"message": isMinistryHasUserResult.reason()});
                } else {
                    if (isMinistryHasUserResult) {
                        // Update the status.
                        boolean|error status = updateStatus(body, applicationId);
                        if (status is boolean && status) {
                            log:printDebug("Successfully update the status as " + body.progress + ".");
                            response.statusCode = http:STATUS_OK;
                            response.setPayload({"message": "Successfully update the status."});
                        } else {
                            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                            if (status is error) {
                                log:printDebug("Error occured is " + status.reason() + ".");
                                response.setPayload(<@untainted>{"message": status.reason()});
                            } else {
                                log:printDebug("Unable to update the status. Please try again later.");
                                response.setPayload({"message": "Unable to update the status. Please try again later."});
                            }
                        }
                    } else {
                        response.statusCode = http:STATUS_NOT_FOUND;
                        response.setPayload({"message": "Ministry doesn't have the corresponding user."});
                    }
                }
            } else {
                response.statusCode = http:STATUS_UNAUTHORIZED;
                response.setPayload({"message": "Requested user and the body information missmatched."});
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            response.setPayload({message: "Unauthorized operation. Try again with valid credentials."});
        }
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/applications/{applicationId}/versions"
    }
    resource function getApplicationVersionsByApplicationId(http:Caller caller, http:Request req, string applicationId) returns error? {

    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/application/{applicationId}/versions/{versionId}"
    }
    resource function getApplicationVersionByVersionId(http:Caller caller, http:Request req, string applicationId, string versionId) returns error? {

    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/application/{applicationId}/status"
    }
    resource function getApplicationStatusById(http:Caller caller, http:Request req, string applicationId) returns error? {

    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/application/{applicationId}/status/{statusId}/versions"
    }
    resource function getApplicationStatusVersions(http:Caller caller, http:Request req, string applicationId, string statusId) returns error? {

    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/maps/reservation"
    }
    resource function getReservations(http:Caller caller, http:Request req) returns error? {

    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/maps/validate-map",
        body: "body"
    }
    resource function validateTheArea(http:Caller caller, http:Request req, Location[] body) returns error? {

    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/applications/{applicationId}/comments"
    }
    resource function getApplicationComments(http:Caller caller, http:Request req, string applicationId) returns error? {

        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error userInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (userInfoFromJWT is [string, string]) {
            [string, string] [userId, userType] = userInfoFromJWT;
            log:printDebug("User information - user ID: " + userId + ", user type: " + userType + ".");
            boolean|error isApplicationRelatedToResult = isApplicationRelatedTo(userType, userId, applicationId);
            if (isApplicationRelatedToResult is boolean && isApplicationRelatedToResult) {
                log:printDebug("Application with ID : " + applicationId + " related to the user with ID: " 
                    + userId + " is found.");
                json|error comments = getComments(applicationId);
                if (comments is json) {
                    log:printDebug("Successfully retrieved comments.");
                    response.statusCode = http:STATUS_OK;
                    response.setPayload(<@untainted>{comments: comments}); 
                } else {
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    log:printDebug("Error occurred while retrieving comments: " 
                        + comments.toString() +".");
                    response.setPayload(<@untainted>{message: comments.reason()}); 
                }
            } else {
                if (isApplicationRelatedToResult is error) {
                    log:printDebug("Error occurred while checking whether the application is related to the user with ID " 
                        + userId + ", and the error occured is " + isApplicationRelatedToResult.toString() + ".");
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    response.setPayload(<@untainted>{message: isApplicationRelatedToResult.reason()}); 
                } else {
                    log:printDebug("Application with ID : " + applicationId 
                        + " related to the user with ID " + userId + "  is not found.");
                    response.statusCode = http:STATUS_NOT_FOUND;
                    response.setPayload({message: "Application is not found."});                    
                }
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            response.setPayload({message: "Unauthorized operation. Try again with valid credentials."});
        }
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/applications/{applicationId}/comments",
        body: "body"
    }
    resource function postApplicationComment(http:Caller caller, http:Request req, string applicationId, Message body) returns error? {
     
        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error userInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (userInfoFromJWT is [string, string]) {
            [string, string] [userId, userType] = userInfoFromJWT;
            log:printDebug("User information - user ID: " + userId + ", user type: " + userType + ".");
            if (body.sender.id == userId) {
                boolean|error isApplicationRelatedToResult = isApplicationRelatedTo(userType, userId, applicationId);
                if (isApplicationRelatedToResult is boolean && isApplicationRelatedToResult) {
                    log:printDebug("Application with ID : " + applicationId + " related to the user with ID " 
                        + userId + " is found.");
                    boolean|error postCommentInApplicationResult = postCommentInApplication(applicationId,body);
                    if (postCommentInApplicationResult is boolean && postCommentInApplicationResult) {
                        log:printDebug("Succesfully posted the comment.");
                        response.statusCode = http:STATUS_OK;
                        response.setPayload({message: "Succesfully posted."}); 
                    } else {
                        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                        if (postCommentInApplicationResult is error) {
                            log:printDebug("Error occurred while posting the comment: " 
                            + postCommentInApplicationResult.toString() +".");
                            response.setPayload(<@untainted>{message: postCommentInApplicationResult.reason()}); 
                        } else {
                            log:printDebug("Comment is not posted.");
                            response.setPayload({message: "Comment is not posted."}); 
                        }
                    }
                } else {
                    if (isApplicationRelatedToResult is error) {
                        log:printDebug("Error occurred while checking whether the application is related to the user with ID " 
                            + userId + ", and the error occured is " + isApplicationRelatedToResult.toString() + ".");
                        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                        response.setPayload(<@untainted>{message: isApplicationRelatedToResult.reason()}); 
                    } else {
                        log:printDebug("Application with ID: " + applicationId 
                            + " related to the user with ID: " + userId + " is not found.");
                        response.statusCode = http:STATUS_NOT_FOUND;
                        response.setPayload({message: "Application is not found."}); 
                    }
                }
            } else {
                response.statusCode = http:STATUS_UNAUTHORIZED;
                response.setPayload({message: "Unauthorized operation. Try again with valid credentials."}); 
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            response.setPayload({message: "Unauthorized operation. Try again with valid credentials."});
        }
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/applications/{applicationId}/comments/{commentId}"
    }
    resource function getApplicationComment(http:Caller caller, http:Request req, string applicationId, string commentId) returns error? {
        
        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error userInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (userInfoFromJWT is [string, string]) {
            [string, string] [userId, userType] = userInfoFromJWT;
            log:printDebug("User information - user ID: " + userId + ", user type: " + userType + ".");
            boolean|error isApplicationRelatedToResult = isApplicationRelatedTo(userType, userId, applicationId);
            if (isApplicationRelatedToResult is boolean && isApplicationRelatedToResult) {
                log:printDebug("Application with ID : " + applicationId + " related to the user with ID: " 
                    + userId + " is found.");
                json|error comment = getComment(applicationId, commentId);
                if (comment is json) {
                    log:printDebug("Successfully retrieved the comment.");
                    response.statusCode = http:STATUS_OK;
                    response.setPayload(<@untainted>{comment: comment}); 
                } else {
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    log:printDebug("Error occurred while retrieving the comment: " 
                        + comment.toString() + ".");
                    response.setPayload(<@untainted>{message: comment.reason()}); 
                }
            } else {
                if (isApplicationRelatedToResult is error) {
                    log:printDebug("Error occured while checking the application is related to the user with ID " 
                        + userId + ", and the error occurred is " + isApplicationRelatedToResult.toString() + ".");
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    response.setPayload(<@untainted>{message: isApplicationRelatedToResult.reason()}); 
                } else {
                    log:printDebug("Application with ID : " + applicationId 
                        + " related to the user with ID: " + userId + " is not found.");
                    response.statusCode = http:STATUS_NOT_FOUND;
                    response.setPayload({message: "Application is not found."});                    
                }
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            response.setPayload({message: "Unauthorized operation. Try again with valid credentials."});
        }
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/comments"
    }
    resource function getComments(http:Caller caller, http:Request req) returns error? {

    }

}
