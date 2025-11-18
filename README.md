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
    pip install flask
    ```

3. Start the Flask server:
    ```bash
    python server.py
    ```

4. Open the browser at:
    ```
    http://<server-ip>:5000
    ```


### Client-side: agent auto-installation

1. Make sure the "**Find My Device**" service is enabled in Windows.
   
2. Run `agent_installer.ps1` **with administrative privileges**.

3. Set the correct URL for the `Invoke-RestMethod` of `position.ps1` when prompted.

---

## Manual Task Scheduler Configuration (optional)

*If you do not want to run the automatic agent installation, you can proceed manually as follows:*

To automate sending the PC location, create a scheduled task that runs the `.bat` file.  
The `.bat` file in turn executes the `.vbs` script silently in the background.

- **Trigger**: at your preferred interval (e.g., every 30 minutes).  
- **Action**: Run `tracker.bat`.  
- **Option**: check "Run whether user is logged on or not".

### PowerShell Process Cleanup

Since the PowerShell script remains in the background to send JSON, it is recommended to schedule a **cleanup task**:

- Create a separate scheduled task that runs `cleanup.bat` about **10 minutes after sending the location**.  
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

## Monitor PCs Outside Local Network

By default, the Flask server runs on `0.0.0.0` and is accessible only on the PC (or on the network) where it is running.  
In order to monitor multiple PCs from different networks (e.g., outside your local LAN), you need to make the web interface **publicly reachable**.

**Example with Pinggy:**

1. Start the Flask server on your PC:
    ```bash
    python server.py
    ```

2. Use [Pinggy](https://pinggy.iok/) to create a public link to your local server. This exposes `http://localhost:5000` to the internet via a secure temporary URL.

3. On the remote PCs, configure the PowerShell script to send the position to the **Pinggy public URL** (`https://<pinggy-url>/update_position`) instead of `http://localhost:5000/update_position`.  

4. Now you can view all devices in real-time through the public link, while the server running on your PC collects and stores the location data.

---

## Important Notes

- Exposing your server publicly should be done carefully; ***ensure the link is shared only with trusted users***.  
- The Flask server must be running on your PC to collect positions. Pinggy only tunnels traffic; it does not replace the server.
- WinTrack is intended for **legitimate internal use**, e.g., monitoring company devices.  
- It does not collect personal data beyond device locations.  
- The `positions.json` file can be initially reset with:
    ```json
    {}
    ```

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


