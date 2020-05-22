import ballerina/http;

listener http:Listener ep1 = new (9080);

@http:ServiceConfig {
    basePath: "/"
}
service authservice on ep1 {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/authenticate"
    }
    resource function authenticate(http:Caller caller, http:Request req) returns error? {

    }
}
