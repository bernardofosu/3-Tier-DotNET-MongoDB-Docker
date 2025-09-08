# 3-Tier .NET & MongoDB Application

This project is a 3-tier web application built with .NET and MongoDB. The application consists of a presentation layer, a business logic layer, and a data access layer. MongoDB is used as the database to store and manage application data.

## Table of Contents

- [3-Tier .NET \& MongoDB Application](#3-tier-net--mongodb-application)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
    - [1. Installing .NET SDK and Runtime](#1-installing-net-sdk-and-runtime)
    - [2. Installing MongoDB](#2-installing-mongodb)
    - [3. Setting Up MongoDB](#3-setting-up-mongodb)
  - [Running the Application](#running-the-application)
  - [Using MongoDB Shell](#using-mongodb-shell)
  - [Use mongodb container](#use-mongodb-container)
  - [License](#license)

## Prerequisites

Before setting up the project, ensure you have the following installed on your machine:

- Ubuntu (or another compatible Linux distribution)
- [.NET SDK 8.0](https://dotnet.microsoft.com/download/dotnet/8.0) 
- [MongoDB 7.0](https://www.mongodb.com/try/download/community) 

## Installation

### 1. Installing .NET SDK and Runtime

To install the .NET SDK and Runtime, execute the following commands in your terminal:

1. **Install .NET SDK 8.0:**

   ```bash
   sudo apt-get update && \
   sudo apt-get install -y dotnet-sdk-8.0
   ```

2. **Install .NET Runtime 8.0:**

   ```bash
   sudo apt-get update && \
   sudo apt-get install -y aspnetcore-runtime-8.0
   ```

### 2. Installing MongoDB

To install MongoDB, execute the following commands in your terminal:

1. **Add MongoDB's GPG key and repository:**

   ```bash
   curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor
   ```

   ```bash
   echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
   ```

2. **Install MongoDB:**

   ```bash
   sudo apt update
   sudo apt install -y mongodb-org
   ```

3. **Enable and Start MongoDB service:**

   ```bash
   sudo systemctl enable mongod
   sudo systemctl start mongod
   ```

### 3. Setting Up MongoDB

1. **Install MongoDB Shell:**

   Follow the installation guide at [MongoDB Shell Installation](https://www.mongodb.com/docs/mongodb-shell/install/).

2. **Access MongoDB Terminal:**

   To interact with your MongoDB instance, open the MongoDB shell using:

   ```bash
   mongosh
   ```

3. **Manipulate Databases and Collections:**

   - Show databases:

     ```bash
     show dbs;
     ```

   - Use a specific database:

     ```bash
     use db_name;
     ```

   - Show collections in the database:

     ```bash
     show collections;
     ```

   - Query the `Products` collection:

     ```bash
     db.Products.find().pretty();
     ```

## Running the Application

To run the .NET application:

1. **Navigate to the root directory where `Program.cs` is located.**

2. **Build the application:**

   ```bash
   dotnet build
   ```

3. **Run the application:**

   ```bash
   dotnet run
   ```

   The application will start, and you can access it in your web browser.

## Using MongoDB Shell

To manipulate your MongoDB database using MongoDB Shell:

1. **Start the shell:**

   ```bash
   mongosh
   ```

2. **Example commands:**

   - **List all databases:**

     ```bash
     show dbs;
     ```

   - **Switch to a specific database:**

     ```bash
     use db_name;
     ```

   - **Show collections in the current database:**

     ```bash
     show collections;
     ```

   - **Find all documents in a collection:**

     ```bash
     db.Products.find().pretty();
     ```

```sh
docker-compose up --build
docker-compose down
```

## Use mongodb container

From your host machine (no need to enter bash):, open a new tab
```sh
docker exec -it mongodb mongosh -u root -p <password> --authenticationDatabase admin
```

Replace <password> with the one you set in your docker-compose.yml (under MONGO_INITDB_ROOT_PASSWORD).

If you’re already inside the container

Just run:
```sh
mongosh -u root -p example --authenticationDatabase admin
```

Then you can do: check the informations appsettings.json
```sh
show dbs
use ProductDB
show Products
db.Products.find().pretty()
```

🗑️ Deleting Documents in MongoDB
1. Delete a single document
```sh
db.Products.deleteOne({ Name: "Apple" })
```

👉 Removes the first document where Name is "Apple".

1. Delete multiple documents
```sh
db.Products.deleteMany({ Category: "Vegetables" })
```

👉 Removes all documents in the Vegetables category.

1. Delete by _id

Since _id is unique:
```sh
db.Products.deleteOne({ _id: ObjectId("68bf49f590523d26ebd1306b") })
```

👉 Deletes the document with that exact ID.

4. Delete all documents (clear collection)
```sh
db.Products.deleteMany({})
```

1. Drop the entire collection
```sh
db.Products.drop()
```

👉 Deletes the whole Products collection (including indexes).

✅ Example in your case:
```sh
db.Products.deleteOne({ Name: "Meat" })
```

will delete only the "Meat" record.

⚠️ Warning: deleteMany({}) or drop() will remove everything. Use carefully.

👉 Do you want me to also show you how to update documents (e.g., change Price: "10" → Price: "12") so you can edit instead of deleting?

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

