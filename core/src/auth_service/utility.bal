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
