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

# The `getUser` function will authenticate the user with the given email and the hashed password.
# 
# + email - Email of the user.
# + password - Password of the user.
# + return - This function will return either the user information as json or an appropriate error.
function getUser(string email, string password) returns json|error {
    map<json>[] users = check usersCollection->find({email: email, password: password});
    map<json>[] find = check usersCollection->find({email: email});
    if (find.length() == 0) {
        return error("No user found", message = "Couldn't find the user with given credentials.");
    } else {
        if (find.length() == users.length()) {
            string id = check trap <string>users[0].id;
            return constructUserInformation(id, "User");
        } else {
            return error("Incorrect password", message = "Incorrect password entered.");
        }
    }
}

# The `getMinistryEmployee` function will authenticate minitry user with given email and hashed password.
# 
# + email - Email of the Ministry user.
# + password - Password of the Ministry user.
# + return - This function will return either the ministry user's information as json or an appropriate error.
function getMinistryEmployee(string email, string password) returns json|error {
    map<json>[] ministries = check ministryCollection->find();
    foreach json ministry in ministries {
        json[] users = <json[]>ministry.users;
        foreach json user in users {
            string userEmail = check trap <string>user.email;
            string userPassword = check trap <string>user.password;
            if (email == userEmail) {
                if (password == userPassword) {
                    string userId = check trap <string>user.id;
                    return constructUserInformation(userId, "Ministry");
                } else {
                    return error("Incorrect password", message = "Incorrect password entered.");
                }
            }
        }
    }
    return error("No user found", message = "Couldn't find the user with given credentials.");
}

# The `getAdmin` function will authenticate admin with given email and hashed password.
# 
# + email - Email of the admin.
# + password - Password of the admin.
# + return - This function will return either admin's information as json or an appropriate error.
function getAdmin(string email, string password) returns json|error {
    map<json>[] users = check adminCollection->find({email: email, password: password});
    map<json>[] find = check adminCollection->find({email: email});
    if (find.length() == 0) {
        return error("No user found", message = "Couldn't find the user with given credentials.");
    } else {
        if (find.length() == users.length()) {
            string id = check trap <string>find[0].id;
            return constructUserInformation(id, "Admin");
        } else {
            return error("Incorrect password", message = "Incorrect password entered.");
        }

    }
}
