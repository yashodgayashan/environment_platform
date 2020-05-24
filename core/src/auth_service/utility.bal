import ballerina/config as conf;
import ballerina/crypto;
import ballerina/jwt;
import ballerina/time;

# The `generateJWT` will generate the JWT token for the given user credentials.
# 
# + credentials - User credentials.
# + return - This function will return either JWT or an appropriate error
function generateJWT(json credentials) returns string|error {

    [string, string] [email, password] = check extractCredentials(credentials);
    json|error authenticateUserResult = authenticateUser(email, password);
    if (authenticateUserResult is json) {

        // Get id and userType.
        string id = check trap <string>authenticateUserResult.id;
        string scope = check trap <string>authenticateUserResult.userType;

        // keyStore setup.
        crypto:KeyStore keyStore = {
            path: "resources/ballerinaKeystore.p12",
            password: conf:getAsString("KEY_STORE_PASSWORD")
        };

        jwt:JwtKeyStoreConfig keyStoreConfig = {
            keyStore: keyStore,
            keyAlias: "ballerina",
            keyPassword: "ballerina"
        };

        // Set JWT header.
        jwt:JwtHeader header = {};
        header.alg = jwt:RS256;
        header.typ = "JWT";

        // Set JWT payload.
        jwt:JwtPayload payload = {};
        payload.sub = "Auth token";
        payload.iss = "environment platform";
        payload.jti = "100078234ba23";
        payload.customClaims = {name: id, scope: scope};
        payload.exp = time:currentTime().time / 1000 + conf:getAsInt("JWT_EXPIRE", 3600);
        payload.iat = time:currentTime().time / 1000;
        string jwt = check jwt:issueJwt(header, payload, keyStoreConfig);
        return jwt;
    } else {
        return authenticateUserResult;
    }
}

# The `getHashedPassword` will convert the given password to SHA265 encoded string.
# 
# + password - Password to be hashed.
# + return - This function will return the hashed value of the given password using SHA256 with base 16.
function getHashedPassword(string password) returns string {

    byte[] passwordByteArray = password.toBytes();
    byte[] hashedPassword = crypto:hashSha256(passwordByteArray);
    return hashedPassword.toBase16();
}

# The `constructUserInformation` will construct user information into a json.
# 
# + id - Id of the user.
# + userType - UserType of the user.
# + return - This function will return the id and the usertype as a json.
function constructUserInformation(string id, string userType) returns json {
    return {id: id, userType: userType};
}

# The `authenticateUser` function will get the Id and the userType of the user if valid email and password given.
# 
# + email - Email of the user.
# + password - Password of the user.
# + return - This function will either return the authenticated user Id and the user type or an appropriate error.
function authenticateUser(string email, string password) returns json|error {

    string hashedPassword = getHashedPassword(password);
    json|error user = getUser(email, hashedPassword);
    if (user is json || user.reason() == "Incorrect password" || user.reason() == "Multiple users") {
        return <@taint>user;
    }
    json|error admin = getAdmin(email, hashedPassword);
    if (admin is json || admin.reason() == "Incorrect password" || admin.reason() == "Multiple users") {
        return <@taint>admin;
    }
    json|error ministry = getMinistryEmployee(email, hashedPassword);
    if (ministry is json || ministry.reason() == "Incorrect password") {
        return <@taint>ministry;
    }
    return error("No user found", message = "Couldn't find the user with the given credentials.");
}

# The `extractCredentials` function will extract the user information from a json 
# and return the separated email and password.
# 
# + credentials - User credentials including email and password
# + return - This function will return either email and password or data converstion error 
# if any of field is empty.
function extractCredentials(json credentials) returns [string, string]|error {
    string email = check trap <string>credentials.email;
    string password = check trap <string>credentials.password;
    return [email, password];
}
