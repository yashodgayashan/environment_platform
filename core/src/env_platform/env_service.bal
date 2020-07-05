import ballerina/config as conf;
import ballerina/http;
import ballerina/jwt;
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
            [boolean, string]|error saveApplicationResult = saveApplication(body, userId);
            if (saveApplicationResult is error) {
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            } else {
                [boolean, string] [isSaved, applicationId] = saveApplicationResult;
                response.statusCode = http:STATUS_CREATED;
                response.setPayload(<@untainted>{"applicationId": applicationId});
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
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
    resource function putApplicationById(http:Caller caller, http:Request req, string applicationId, TreeRemovalForm body) returns error? {

        http:Response response = new;
        string authHeader = req.getHeader("Authorization");
        [string, string]|error userInfoFromJWT = getUserInfoFromJWT(authHeader);
        if (userInfoFromJWT is [string, string]) {
            [string, string] [userId, userType] = userInfoFromJWT;
            boolean|error applicationBelongsToUserResult = applicationBelongsToUser(applicationId, userId);
            if (applicationBelongsToUserResult is error) {
                response.statusCode = http:STATUS_NOT_FOUND;
                if (applicationBelongsToUserResult.reason() == "No applications") {
                    response.setPayload({"reason": "No applications for given user."});
                } else {
                    response.setPayload({"reason": "No such user."});
                }
            } else {
                // If application is found.
                if (applicationBelongsToUserResult) {
                    boolean|error application = updateApplication(body, applicationId);
                    if (application is error) {
                        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                        response.setPayload({"reason": "Application is not updated."});
                    } else {
                        // If application is updated.
                        if (application) {
                            response.statusCode = http:STATUS_OK;
                            response.setPayload({"reason": "Application is updated."});
                        } else {
                            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                            response.setPayload({"reason": "Application is not updated."});
                        }
                    }
                } else {
                    response.statusCode = http:STATUS_NOT_FOUND;
                    response.setPayload({"reason": "Application is not submitted by the given user"});
                }
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
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
            boolean|error userHasApplicationResult = userHasApplication(applicationId, userId);
            if (userHasApplicationResult is error) {
                response.statusCode = http:STATUS_NOT_FOUND;
                if (userHasApplicationResult.reason() == "No applications") {
                    response.setPayload({"reason": "No applications for given user"});
                } else {
                    response.setPayload({"reason": "No such user"});
                }
            } else {
                boolean|error application = deleteApplication(applicationId, userId);
                if (application is error) {
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    response.setPayload({"reason": "Application is not deleted"});
                } else {
                    // If application is deleted.
                    if (application) {
                        response.statusCode = http:STATUS_OK;
                        response.setPayload({"reason": "Application is deleted"});
                    } else {
                        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                        response.setPayload({"reason": "Application is not deleted"});
                    }
                }
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
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

            boolean|error assignMinistryResult = assignMinistry(body, applicationId, adminId);
            if (assignMinistryResult is error) {
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                response.setPayload({"message": "Failed to assigned the ministry"});
            } else {
                if (assignMinistryResult) {
                    response.statusCode = http:STATUS_OK;
                    response.setPayload({"message": "Successfully assigned the ministry"});
                } else {
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    response.setPayload({"message": "Failed to assigned the ministry"});
                }
            }
        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
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
            if (body.changedBy.id == userId) {

                // Check whether ministry has such user.
                boolean|error isMinistryHasUserResult = isMinistryHasUser(body.ministry.id, userId);
                if (isMinistryHasUserResult is error) {
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    response.setPayload({"message": "Unable to update the status."});
                } else {
                    if (isMinistryHasUserResult) {

                        // Update the status.
                        boolean|error status = updateStatus(body, applicationId);
                        if (status is error) {
                            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                            response.setPayload({"message": "Unable to update the status."});
                        } else {
                            if (status) {
                                response.statusCode = http:STATUS_OK;
                                response.setPayload({"message": "Successfully update the status."});

                            } else {
                                response.statusCode = http:STATUS_NOT_FOUND;
                                response.setPayload({"message": "Unable to update the status."});

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

    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/applications/{applicationId}/comments",
        body: "body"
    }
    resource function postApplicationComment(http:Caller caller, http:Request req, string applicationId, Message body) returns error? {

    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/applications/{applicationId}/comments/{commentId}"
    }
    resource function getApplicationComment(http:Caller caller, http:Request req, string applicationId, string commentId) returns error? {

    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/comments"
    }
    resource function getComments(http:Caller caller, http:Request req) returns error? {

    }

}
