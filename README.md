# WinTrack
<img width="1713" height="318" alt="logo" src="https://github.com/user-attachments/assets/5b93d014-4db7-4d30-8914-73b03ec29f12" />

**WinTrack** is a simple Windows PC location tracking tool in real-time, designed to monitor multiple Windows devices on an interactive map. The application is built in Python using Flask and Leaflet.js, and allows viewing the location history or clearing it easily.

---

## Main Features

- Track Windows PC locations with automatic updates.
- View historical positions with "Back" and "Forward" buttons.
- Easily clear position history with a single click.
- Modern and responsive web interface with interactive Leaflet.js map.
- Supports multiple devices simultaneously.

---

## Tools Used

- **Python 3.13** with **Flask** for the local server.
- **Leaflet.js** for map visualization.
- **HTML / CSS / JS** for the web interface.
- **PowerShell** to send PC location data.
- **VBScript (.vbs)** to run PowerShell scripts silently in the background.
- **Task Scheduler** to automate periodic position updates.
- Optional: **Pinggy** to expose the Flask server online easily.

---

## Installation and Running

### Server-side

1. Clone the repository:
    ```bash
    git clone https://github.com/Uriel-SG/WinTrack.git
    cd WinTrack
    ```

2. Install Python dependencies:
    ```bash
    pip install flask Flask-Limiter Flask-HTTPAuth
    ```

3. Create an API key for WinTrack as a System Variable:

   *Windows:*
    ```bash
    setx WINTRACK_API_KEY "YOUR_API_KEY" /M
     ```
    *Linux:*
    ```bash
    sudo sh -c 'echo "export WINTRACK_API_KEY=YOUR_API_KEY" >> /etc/environment'
     ```
4. Create the credentials for WinTrack as System Variable:

    *Windows:*
    ```bash
    setx WINTRACK_AUTH_USER "YOUR_USERNAME" /M
    ```
    ```bash
    setx WINTRACK_AUTH_PASS "YOUR_PASSWORD" /M
    ```
    *Linux:*
    ```bash
    sudo sh -c 'echo "export WINTRACK_AUTH_USER=YOUR_USERNAME" >> /etc/environment'
     ```
    ```bash
    sudo sh -c 'echo "export WINTRACK_AUTH_PASS=YOUR_PASSWORD" >> /etc/environment'
     ```

6. Start the Flask server:
    ```bash
    python server.py
    ```

7. Open the browser at:
    ```
    http://<server-ip>:5000
    ```


### Client-side: agent auto-installation

1. Make sure the "**Find My Device**" service is enabled in Windows.
   
2. Run `agent_installer.ps1` **with administrative privileges** or, alternatively, run the following ***one‑liner*** as administrator, which will **automatically execute the installer script on the target host**:
    ```
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "iex (Invoke-WebRequest 'https://raw.githubusercontent.com/Uriel-SG/WinTrack/main/agent_installer.ps1' -UseBasicParsing).Content"
    ```

3. Set the correct URL for the `Invoke-RestMethod` of `position.ps1`, the chosen `API Key` and the chosen `credentials` when prompted.

---

## Manual Task Scheduler Configuration (optional)

*If you do not want to run the automatic agent installation, you can proceed manually as follows:*

Set the correct URL in the `Invoke-RestMethod` field of `position.ps1`.

Set the system-wide API key on the endpoint with: `setx WINTRACK_API_KEY "YOUR_API_KEY" /M`
Set the system-wide Username on the endpoint with: `setx WINTRACK_AUTH_USER "YOUR_USERNAME" /M`
Set the system-wide Password on the endpoint with: `setx WINTRACK_AUTH_PASS "YOUR_PASSWORD" /M`

To automate sending the PC location, create a scheduled task that runs the `.bat` file.  
The `.bat` file in turn executes the `.vbs` script silently in the background.

- **Trigger**: at your preferred interval (e.g., every 10 minutes).  
- **Action**: Run `tracker.bat`.  
- **Option**: check "Run whether user is logged on or not".

### PowerShell Process Cleanup

Since the PowerShell script remains in the background to send JSON, it is recommended to schedule a **cleanup task**:

- Create a separate scheduled task that runs `cleanup.bat` about **20 minutes after sending the location**.  
- This frees any residual PowerShell processes and avoids memory accumulation.

---

## JSON Data

Positions are saved in `positions.json` in the following format:

```json
{
  "DeviceName1": [
    {
      "lat": 41.890210,
      "lon": 12.492231,
      "timestamp": "15-11-2025 23:08"
    }
  ],
  "DeviceName2": [
    ...
  ]
}
```

---

## Deployment and Connectivity

By default, the Flask server runs on `0.0.0.0` and is accessible only on the PC (or on the network) where it is running.  
In order to monitor multiple PCs from different networks (e.g., outside your local LAN), you need to make the web interface **publicly reachable**.

### A. Simple Testing / Local Network Exposure

**Example with Pinggy:**

1. Start the Flask server on your PC:
    ```bash
    python server.py
    ```

2. Use [Pinggy](https://pinggy.io/) to create a public link to your local server. This exposes `http://localhost:5000` to the internet via a secure temporary URL.

3. On the remote PCs, configure the PowerShell script to send the position to the **Pinggy public URL** (`https://<pinggy-url>/update_position`) instead of `http://localhost:5000/update_position`.  

4. Now you can view all devices in real-time through the public link, while the server running on your PC collects and stores the location data.

### B. Solutions for Corporate Production Environments
⚠️ **WARNING: Tunneling services like Pinggy or Ngrok are strictly not recommended for production, mission-critical, or security-sensitive corporate deployments. They introduce external dependencies, performance bottlenecks, and security uncertainties.** ⚠️

**1. Dedicated Web Server (Gunicorn, Waitress, etc.)**

For reliable, secure, and scalable distribution within a company, you should use a **dedicated Web Server** (*Gunicorn*, *Waitress*, etc.)

Flask's built-in server is **only for development** (debug=True). In a production environment, you must deploy the application using a robust Web Server Gateway Interface (**WSGI**) server.

Example: *Waitress*

*Waitress is a production-quality, pure Python WSGI server known for its simplicity and reliability also on Windows environments.*

Instead of running python server.py, you would run the server using Waitress: [Waitress Official](https://flask.palletsprojects.com/en/stable/deploying/waitress/)

**2. Corporate Network and Firewall Configuration**

To ensure accessibility **without compromising network security**, work with your IT team to configure the corporate firewall and proxy:

- **Dedicated Server:** Deploy the Waitress-powered Flask server on a dedicated, secured host (e.g., a virtual machine or a physical server).

- **Firewall Rules:** Configure the server's local firewall and the corporate network firewall to explicitly allow incoming traffic only to the port used by Waitress (e.g., 8080) and only from the necessary IP ranges (e.g., the subnets containing the monitored PCs).

- **Static IP/Domain:** Use a stable, internal Static IP or, preferably, an internal DNS record (e.g., wintrack-api.internal.company.com) to ensure the client scripts always point to a reliable location.

*By following these professional steps, you ensure the integrity, scalability, and security required for an enterprise-level monitoring application.*

---

## Security Features

### 1. API Key Authentication
All position updates sent to the server *must include a valid API key in the* `X-API-Key` HTTP header.

**The server verifies this key before accepting or processing any incoming payload.**

This mechanism ensures that:

- Only authorized agents can submit geolocation data;

- Unauthorized clients, scanners, or malicious scripts are immediately rejected;

API keys can be rotated or revoked at any time without modifying the agent code.

The API key is stored as a system environment variable (`WINTRACK_API_KEY`) on the server to avoid embedding secrets in the source code or repository.

### 2. Basic Authentication (Web Interface Protection)

Access to the tracking interface (the root URL `/`) and the data retrieval endpoint (`/get_positions`) is secured using HTTP Basic Authentication. 
This mechanism **requires a *username* and *password* before the user can view the map, the raw data or submit position data via the `/update_position` endpoint.**

This ensures that:

- *The web interface is only accessible to authorized administrators or internal users.*

- *The authentication process is handled by standard web protocols, providing robust browser compatibility.*

The credentials (username: WINTRACK_AUTH_USER and password: WINTRACK_AUTH_PASS) are stored as system environment variables on the server.

### 3. JSON format
Only POST requests that **strictly follow the defined JSON format** are accepted. 
Any other request type or malformed payload is automatically rejected to ensure data integrity and prevent misuse.

### 4. Rate Limiting (DoS Protection)
The server implements request rate limiting on critical endpoints using `Flask-Limiter`.

Rate limiting provides:

- *Protection against brute-force or flood attacks.*

- *Controlled access to high-frequency endpoints, such as /update_position.*

- *Automatic throttling of clients that exceed predefined request thresholds.*

This helps maintain service **availability** and prevents malicious clients from overwhelming the server with excessive traffic.


---

## Important Notes

- WinTrack is intended for **legitimate internal use**, e.g., monitoring company devices.
- It does not collect personal data beyond device locations.
- Exposing your server publicly should be done carefully; ***ensure the link is shared only with trusted users***.  
- The Flask server must be running on your PC to collect positions. Pinggy only tunnels traffic; it does not replace the server.
- If you have an especially effective antivirus or antimalware solution, you may need to add the wintrack folder to the exceptions.  

---

## Screenshots

<img width="1592" height="977" alt="screen" src="https://github.com/user-attachments/assets/5a811abe-9c98-4d34-a32a-d64524867bb8" />


---

## Contributing

*Feel free to fork this repository and submit pull requests!*
*Whether it’s improving the UI, adding new features, or optimizing the scripts, all contributions are welcome.*

---

**Author:** Uriel-SG  
**License:** MIT


