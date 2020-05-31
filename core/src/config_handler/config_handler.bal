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
mongodb:Collection applicationCollection = check mongoDatabase->getCollection("applications");
mongodb:Collection userCollection = check mongoDatabase->getCollection("users");
mongodb:Collection ministryCollection = check mongoDatabase->getCollection("ministries");
mongodb:Collection adminCollection = check mongoDatabase->getCollection("admins");
mongodb:Collection applicationMetaDataCollection = check mongoDatabase->getCollection("applicationMetaData");

# Retrieve the applications collection.
#
# + return - Applications collection stored in mongodb.
public function getApplicationCollection() returns mongodb:Collection {
    return applicationCollection;
}

# Retrieve the user collection.
#
# + return - User collection stored in mongodb.
public function getUserCollection() returns mongodb:Collection {
    return userCollection;
}

# Retrieve the minstry collection.
#
# + return - Ministry collection stored in mongodb.
public function getMinistryCollection() returns mongodb:Collection {
    return ministryCollection;
}

# Retrieve the admin collection.
#
# + return - Admin collection stored in mongodb.
public function getAdminCollection() returns mongodb:Collection {
    return adminCollection;
}

# Retrieve the application metadata collection.
#
# + return - Application metadata collection stored in mongodb.
public function getApplicationMetadataCollection() returns mongodb:Collection {
    return applicationMetaDataCollection;
}
