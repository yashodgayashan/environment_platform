import ballerina/http;
import ballerina/openapi;

listener http:Listener ep0 = new(9090);

@openapi:ServiceInfo {
    contract: "resources/openapi_v3.yaml"
}
@http:ServiceConfig {
    basePath: "/"
}

service envService on ep0 {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications"
    }
    resource function resource_get_applications (http:Caller caller, http:Request req) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/applications",
        body:"body"
    }
    resource function resource_post_applications (http:Caller caller, http:Request req,  TreeRemovalForm  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications/{application-id}"
    }
    resource function resource_get_applications_application-id (http:Caller caller, http:Request req,  string &#x27;application\-id) returns error? {

    }

    @http:ResourceConfig {
        methods:["PUT"],
        path:"/applications/{application-id}",
        body:"body"
    }
    resource function resource_put_applications_application-id (http:Caller caller, http:Request req,  string &#x27;application\-id,  TreeRemovalForm  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/applications/{application-id}"
    }
    resource function resource_delete_applications_application-id (http:Caller caller, http:Request req,  string &#x27;application\-id) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/applications/{application-id}/assign-ministry",
        body:"body"
    }
    resource function resource_post_applications_application-id_assign-ministry (http:Caller caller, http:Request req,  string &#x27;application\-id,  AssignedMinistry  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/applications/{application-id}/update-status",
        body:"body"
    }
    resource function resource_post_applications_application-id_update-status (http:Caller caller, http:Request req,  string &#x27;application\-id,  Status  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications/{application-id}/versions"
    }
    resource function resource_get_applications_application-id_versions (http:Caller caller, http:Request req,  string &#x27;application\-id) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/application/{application-id}/versions/{version-id}"
    }
    resource function resource_get_application_application-id_versions_version-id (http:Caller caller, http:Request req,  string &#x27;application\-id,  string &#x27;version\-id) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/application/{application-id}/status"
    }
    resource function resource_get_application_application-id_status (http:Caller caller, http:Request req,  string &#x27;application\-id,  string &#x27;status\-id) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/application/{application-id}/status/{status-id}/versions"
    }
    resource function resource_get_application_application-id_status_status-id_versions (http:Caller caller, http:Request req,  string &#x27;application\-id,  string &#x27;status\-id) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/maps/reservation"
    }
    resource function resource_get_maps_reservation (http:Caller caller, http:Request req) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/maps/validate-map",
        body:"body"
    }
    resource function resource_post_maps_validate-map (http:Caller caller, http:Request req,  Location  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications/{application-id}/comments"
    }
    resource function resource_get_applications_application-id_comments (http:Caller caller, http:Request req,  string &#x27;application\-id) returns error? {

    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/applications/{application-id}/comments",
        body:"body"
    }
    resource function resource_post_applications_application-id_comments (http:Caller caller, http:Request req,  string &#x27;application\-id,  Message  body) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/applications/{application-id}/comments/{comment-id}"
    }
    resource function resource_get_applications_application-id_comments_comment-id (http:Caller caller, http:Request req,  string &#x27;application\-id,  string &#x27;comment\-id) returns error? {

    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/comments"
    }
    resource function resource_get_comments (http:Caller caller, http:Request req) returns error? {

    }

}
