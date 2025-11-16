let map = L.map('map').setView([0,0], 2);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  maxZoom: 19
}).addTo(map);

let markers = {};
let positionsData = {};
let deviceIndex = {};  // indice corrente per ciascun device

const deviceSelect = document.getElementById("deviceSelect");
const prevBtn = document.getElementById("prev");
const nextBtn = document.getElementById("next");
const clearBtn = document.getElementById("clear");

async function loadPositions() {
  try {
    const res = await fetch('/get_positions');
    const newData = await res.json();

    // aggiorna solo se ci sono nuove posizioni
    let hasNew = false;
    for (const device in newData) {
      if (!positionsData[device] || positionsData[device].length !== newData[device].length) {
        hasNew = true;
        positionsData[device] = newData[device];

        // aggiorna indice all'ultima posizione
        if (!(device in deviceIndex)) {
          deviceIndex[device] = positionsData[device].length - 1;
        } else {
          deviceIndex[device] = positionsData[device].length - 1;
        }
      }
    }

    // aggiorna select dei device
    deviceSelect.innerHTML = "";
    for (const device in positionsData) {
      const option = document.createElement("option");
      option.value = device;
      option.text = device;
      deviceSelect.appendChild(option);
    }

    // aggiorna markers e mappa
    for (const device in positionsData) {
      updateMarker(device);
    }

    // centra la mappa sull'ultima posizione del device selezionato
    if (deviceSelect.value && hasNew) {
      const device = deviceSelect.value;
      const idx = deviceIndex[device];
      const pos = positionsData[device][idx];
      map.setView([pos.lat, pos.lon], 15);
    }

  } catch(e) { console.error(e); }
}

function updateMarker(device) {
  const idx = deviceIndex[device];
  const pos = positionsData[device][idx];
  if (!markers[device]) {
    markers[device] = L.marker([pos.lat, pos.lon]).addTo(map)
      .bindPopup(`<b>${device}</b><br>Lat: ${pos.lat}<br>Lon: ${pos.lon}<br>Ultimo aggiornamento: ${pos.timestamp}`);
  } else {
    markers[device].setLatLng([pos.lat, pos.lon]);
    markers[device].getPopup().setContent(
      `<b>${device}</b><br>Lat: ${pos.lat}<br>Lon: ${pos.lon}<br>Ultimo aggiornamento: ${pos.timestamp}`
    );
  }
}

deviceSelect.addEventListener("change", () => {
  const device = deviceSelect.value;
  updateMarker(device);
  const pos = positionsData[device][deviceIndex[device]];
  map.setView([pos.lat, pos.lon], 15);
});

prevBtn.addEventListener("click", () => {
  const device = deviceSelect.value;
  if (deviceIndex[device] > 0) deviceIndex[device]--;
  updateMarker(device);
  const pos = positionsData[device][deviceIndex[device]];
  map.setView([pos.lat, pos.lon], 15);
});

nextBtn.addEventListener("click", () => {
  const device = deviceSelect.value;
  if (deviceIndex[device] < positionsData[device].length - 1) deviceIndex[device]++;
  updateMarker(device);
  const pos = positionsData[device][deviceIndex[device]];
  map.setView([pos.lat, pos.lon], 15);
});

clearBtn.addEventListener("click", async () => {
  await fetch('/clear_positions', { method: "POST" });
  positionsData = {};
  markers = {};
  deviceIndex = {};
  map.setView([0,0],2);
  deviceSelect.innerHTML = "";
});

// aggiorna ogni 3 secondi
setInterval(loadPositions, 3000);
loadPositions();
