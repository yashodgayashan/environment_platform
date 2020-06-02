import ballerina/config as conf;
import ballerina/http;
import ballerina/jwt;


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

listener http:Listener ep1 = new (9080, config = {
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

@http:ServiceConfig {
    basePath: "/",
    cors: {
        allowOrigins: ["*"]
    }
}
service authservice on ep1 {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/authenticate",
        auth: {
            enabled: false
        }
    }
    resource function authenticate(http:Caller caller, http:Request req) returns @tainted error? {

        http:Response response = new;
        map<json>|error payload = check trap <map<json>>req.getJsonPayload();
        if (payload is error) {
            response.statusCode = http:STATUS_NOT_ACCEPTABLE;
            response.setPayload({reason: "Invalid payload type"});
        } else {
            string|error generateJWTResult = generateJWT(payload);
            if (generateJWTResult is string) {
                response.statusCode = http:STATUS_OK;
                response.setPayload({token: <@taint>generateJWTResult});
            } else {
                response.statusCode = http:STATUS_UNAUTHORIZED;
                response.setPayload({reason: <@taint>generateJWTResult.reason()});
            }
        }
        error? respond = caller->respond(response);
    }

}
