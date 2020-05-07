
type TreeRemovalApplication record { 
     int numberOfVersions;
     int versionNumber;
     string applicationId;
     string title;
     Date applicationCreatedDate;
     Date removalDate;
     string reason;
     string 'type;
     string requestedBy;
     boolean permitRequired;
     string landOwner;
     string treeRemovalAutrhority;
     string city;
     string district;
     string nameOfTheLand;
     string planNumber;
     Location location;
     TreeInformation [] treeInformation;
     Status [] status;
     Field [] addedFields;
     Message [] comments;
};
type AssignedMinistry record { 
     Ministry ministry;
     Person assignedBy;
     Date assignedTime;
     Ministry prerequisite;
};
type TreeRemovalForm record { 
     string status;
     string title;
     Date applicationCreatedDate;
     Date removalDate;
     string reason;
     string 'type;
     string requestedBy;
     boolean permitRequired;
     string landOwner;
     string treeRemovalAuthority;
     string city;
     string district;
     string nameOfTheLand;
     string planNumber;
     Location location;
     TreeInformation [] treeInformation;
};
type Reservation record { 
     string name;
     Location location;
};
type TreeInformation record { 
     string species;
     string treeNumber;
     string heightType;
     int height;
     int girth;
    record {  int minGirth; int maxGirth; int height; }  [] logDetails;
};
type Message record { 
     any sender;
     Date timestamp;
     string message;
};
type Person record { 
     string name;
     string id;
};
type Ministry record { 
     string name;
     string id;
};
type Date record { 
     int year;
     int month;
     int day;
     int hour;
     int minute;
};
type Status record { 
     string 'ministry\-name;
     string progress;
     Person changedBy;
     string reason;
     Date timestamp;
};
type Field record { 
     string fieldName;
     string data;
     Ministry addedBy;
     Date addedOn;
     boolean edited;
};