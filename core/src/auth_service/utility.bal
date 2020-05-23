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

