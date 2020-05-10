import ballerina/http;
import ballerina/openapi;

listener http:Listener ep0 = new(9090);

@openapi:ServiceInfo {
    contract: "../resources/openapi_v3.yaml"
}
@http:ServiceConfig {
    basePath: "/"
}

service envService on ep0 {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications"
    }
    resource function getApplications (http:Caller caller, http:Request req) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/applications",
        body:"body"
    }
    resource function createApplication (http:Caller caller, http:Request req,  TreeRemovalForm  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications/{applicationId}"
    }
    resource function getApplication (http:Caller caller, http:Request req,  string applicationId) returns error? {

    }

    @http:ResourceConfig {
        methods:["PUT"],
        path:"/applications/{applicationId}",
        body:"body"
    }
    resource function updateApplication (http:Caller caller, http:Request req,  string applicationId,  TreeRemovalForm  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/applications/{applicationId}"
    }
    resource function deleteApplication (http:Caller caller, http:Request req,  string applicationId) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/applications/{applicationId}/assign-ministry",
        body:"body"
    }
    resource function assignMinistry (http:Caller caller, http:Request req,  string applicationId,  AssignedMinistry  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/applications/{applicationId}/update-status",
        body:"body"
    }
    resource function updateApplicationStatus (http:Caller caller, http:Request req,  string applicationId,  Status  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications/{applicationId}/versions"
    }
    resource function getApplicationVersions (http:Caller caller, http:Request req,  string applicationId) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/application/{applicationId}/versions/{versionId}"
    }
    resource function getApplicationVersion (http:Caller caller, http:Request req,  string applicationId,  string versionId) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/application/{applicationId}/status"
    }
    resource function getApplicationStatus (http:Caller caller, http:Request req,  string applicationId) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/application/{applicationId}/status/{statusId}/versions"
    }
    resource function getApplicationStatusVersions (http:Caller caller, http:Request req,  string applicationId,  string statusId) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/maps/reservations"
    }
    resource function getReservations (http:Caller caller, http:Request req) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/maps/validate-map",
        body:"body"
    }
    resource function validateMap (http:Caller caller, http:Request req,  Area body) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications/{applicationId}/comments"
    }
    resource function getApplicationComments (http:Caller caller, http:Request req,  string applicationId) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/applications/{applicationId}/comments",
        body:"body"
    }
    resource function createApplicationComment (http:Caller caller, http:Request req,  string applicationId,  Message  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications/{applicationId}/comments/{commentId}"
    }
    resource function getApplicationComment (http:Caller caller, http:Request req,  string applicationId,  string commentId) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/comments"
    }
    resource function getComments (http:Caller caller, http:Request req) returns error? {

    }

}