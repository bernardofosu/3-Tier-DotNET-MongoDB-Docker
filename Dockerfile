# Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# (optional) copy solution for better cache
COPY 3-Tier-DotNET-MongoDB-Docker.sln ./

# copy the project file that is in the ROOT
COPY DotNetMongoCRUDApp.csproj ./
RUN dotnet restore DotNetMongoCRUDApp.csproj

# copy the rest
COPY . .

# publish that project explicitly
RUN dotnet publish DotNetMongoCRUDApp.csproj -c Release -o /app/out

# Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
ENV ASPNETCORE_URLS=http://0.0.0.0:5035
COPY --from=build /app/out .
EXPOSE 5035
ENTRYPOINT ["dotnet","DotNetMongoCRUDApp.dll"]
