import ballerina/config as conf;
import ballerina/mongodb;

// Mongodb configurations.
mongodb:ClientConfig mongoConfig = {
    host: conf:getAsString("DB_HOST"),
    username: conf:getAsString("DB_USER_NAME"),
    password: conf:getAsString("DB_PASSWORD"),
    options: {sslEnabled: false, serverSelectionTimeout: 500}
};
mongodb:Client mongoClient = check new (mongoConfig);
mongodb:Database mongoDatabase = check mongoClient->getDatabase("EnvironmentPlatform");
mongodb:Collection usersCollection = check mongoDatabase->getCollection("users");
mongodb:Collection ministryCollection = check mongoDatabase->getCollection("ministries");
mongodb:Collection adminCollection = check mongoDatabase->getCollection("admins");

# The `getUser` function will authenticate user with given email and hashed password.
# 
# + email - Email of the user.
# + password - Password of the User.
# + return - This function will return either user information as json or an appropriate error.
function getUser(string email, string password) returns json|error {
    map<json>[] users = check usersCollection->find({email: email, password: password});
    map<json>[] find = check usersCollection->find({email: email});
    if (find.length() > 1) {
        return error("Multiple users", message = "There are multiple users with same email:" + email + ".");
    } else if (find.length() == 0) {
        return error("No user found", message = "Couldn't find the user with given credentials");
    } else {
        if (find.length() == users.length()) {
            string id = check trap <string>users[0].id;
            return constructUserInformation(id, "User");
        } else {
            return error("Incorrect password", message = "Incorrect password entered");
        }
    }
}