import ballerina/crypto;

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
# + return - This function will either return the authenticated user Id and the user type or appropriate error.
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
    return error("No user found", message = "Couldn't find the user with given credentials");
}

# The `extractCredentials` function will extract the user information from json 
# asd return seperated email and password.
# 
# + credentials - User credentials including email and password
# + return - This function will return either email and password or data converstion error 
# if any of field is empty.
function extractCredentials(json credentials) returns [string, string]|error {
    string email = check trap <string>credentials.email;
    string password = check trap <string>credentials.password;
    return [email, password];
}
