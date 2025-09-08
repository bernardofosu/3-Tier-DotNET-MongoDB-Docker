# 🧰 Docker & .NET Troubleshooting – Errors & Fixes (with Commands)

Below are the errors you hit (as code snippets) and the exact fixes to apply. Keep this as your runbook. ✅

---

## 1) 🟣 `.csproj` Wildcard Confusion → **“Specify which project or solution file to use…”**

### ❌ Error
```text
MSBUILD : error MSB1011: Specify which project or solution file to use...
```

> Cause: `*.csproj` matched more than one project, so `dotnet publish` didn’t know which to build.

### ✅ Fix — **Use explicit project path** in `Dockerfile`
```dockerfile
# Copy only the target project first (for better layer caching)
COPY DotNetMongoCRUDApp/DotNetMongoCRUDApp.csproj DotNetMongoCRUDApp/
RUN dotnet restore DotNetMongoCRUDApp/DotNetMongoCRUDApp.csproj

# Bring the rest of the source
COPY . ./

# Publish explicitly against the right .csproj
RUN dotnet publish DotNetMongoCRUDApp/DotNetMongoCRUDApp.csproj -c Release -o /app/out
```

**Why this works:** You eliminate ambiguity. Restore/publish target the exact project.

---

## 2) 🟢 MongoDB Container Name Conflict

### ❌ Error
```text
ERROR: for mongodb  Cannot create container for service mongodb: Conflict.
The container name "/mongodb" is already in use by container "f38695ca2b6950...".
You have to remove (or rename) that container to be able to reuse that name.
```

### ✅ Fix — Remove stale container **or** rename the service
```bash
# See all containers
docker ps -a

# Remove the old named container
docker rm mongodb
```

Or set a fixed name in `docker-compose.yml`:
```yaml
services:
  mongodb:
    image: mongo:7.0
    container_name: mongodb
```

---

## 3) 🟡 Port 27017 Already in Use (MongoDB)

### ❌ Error
```text
Cannot start service mongodb: ... failed to bind port 0.0.0.0:27017/tcp:
listen tcp4 0.0.0.0:27017: bind: address already in use
```

### 🕵️‍♂️ Diagnose – **Who’s using 27017?**
```bash
sudo ss -lntp | grep 27017
# or
sudo lsof -iTCP:27017 -sTCP:LISTEN -P -n
```

If it’s a system service (common: `mongod`):
```bash
sudo systemctl status mongod
sudo systemctl stop mongod
sudo systemctl disable mongod
# If installed via Snap:
sudo snap services
sudo snap stop mongodb
```

### ✅ Fix A — **Free port 27017** by stopping local service
Stop/disable `mongod` (above), then bring your stack up again.

### ✅ Fix B — **Remap host port** (use 27018 on host → 27017 in container)
```yaml
services:
  mongodb:
    image: mongo:7
    ports:
      - "27018:27017"   # hostPort:containerPort
```
> Remember to also open/adjust your **security group / firewall** for the new host port.

---

## 4) 🟠 Port 8080 Already in Use (Java/Tomcat grabbing it back)

### ❌ Error
```text
Cannot start service webapp: ... failed to bind port 0.0.0.0:8080/tcp:
listen tcp4 0.0.0.0:8080: bind: address already in use
```

### 🕵️‍♂️ Diagnose
```bash
# Kill whatever is listening (temporary)
sudo fuser -k 8080/tcp

# Check what's listening now
sudo ss -lntp | grep 8080

# Inspect the process
ps -p <PID> -o pid,ppid,cmd
# Example output showed:
# PID=291106  PPID=1  CMD=/usr/lib/jvm/java-17-openjdk... -Dcatalina.home=/opt/apache-tomcat-9.0.65 ...
# -> That's Tomcat started by systemd (PPID=1)
```

### ✅ Fix Option A — **Stop/Disable Tomcat service** (preferred)
```bash
# Look for a unit
sudo systemctl status tomcat9 || sudo systemctl status tomcat || true
sudo systemctl list-units --type=service | grep -i tomcat

# Stop & disable the right unit name you find
sudo systemctl stop tomcat9     # or: tomcat
sudo systemctl disable tomcat9  # or: tomcat

# Confirm port is free
sudo ss -lntp | grep 8080 || echo "8080 free"
```

### ✅ Fix Option B — **Use Tomcat scripts** (when no systemd unit)
```bash
sudo /opt/apache-tomcat-9.0.65/bin/shutdown.sh
# if still running after a few seconds:
sudo /opt/apache-tomcat-9.0.65/bin/catalina.sh stop
```

If it keeps respawning, something starts it. Find & disable the startup entry:
```bash
grep -R "apache-tomcat-9.0.65"   /etc/systemd/system /etc/init.d /etc/rc*.d /etc/rc.local   /var/spool/cron /etc/cron* 2>/dev/null
```

### ✅ Fix Option C — **Change your app’s host port** (quick workaround)
`docker-compose.yml`:
```yaml
services:
  webapp:
    build: .
    ports:
      - "5035:5035"   # host:container
    environment:
      - ASPNETCORE_URLS=http://0.0.0.0:5035
```

`Dockerfile`:
```dockerfile
ENV ASPNETCORE_URLS=http://0.0.0.0:5035
EXPOSE 5035
```

Then:
```bash
docker compose up --build
```

---

## ✅ TL;DR
- **.NET publish**: always reference the **exact** `.csproj`.  
- **MongoDB name conflict**: `docker rm mongodb` or rename service.  
- **27017 busy**: stop local `mongod` or **remap port** (27018→27017).  
- **8080 busy**: **stop/disable Tomcat**, or **change host port** (e.g., 5035).

Happy shipping! 🚀
