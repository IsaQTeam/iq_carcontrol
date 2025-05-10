// Main variables
let isDisplayVisible = false;
let isExpanded = false;
let currentVehicle = {
    doors: [],
    engine: false,
    locked: false
};


// Event listeners
document.addEventListener('DOMContentLoaded', () => {
    // Close button
    document.getElementById('close-btn').addEventListener('click', () => {
        closeDisplay();
    });

    // Door buttons
    document.querySelectorAll('.door-btn').forEach(button => {
        button.addEventListener('click', (e) => {
            const doorId = parseInt(e.currentTarget.id.split('-')[1]);
            toggleDoor(doorId);
        });
    });

    // Seat buttons
    document.querySelectorAll('.seat-btn').forEach(button => {
        button.addEventListener('click', (e) => {
            const seatId = e.currentTarget.id.split('-')[1];
            let seatIndex = parseInt(seatId);
            
            // Handle driver seat (-1)
            if (seatId === 'minus1') {
                seatIndex = -1;
            }
            
            changeSeat(seatIndex);
        });
    });

    // Engine button
    document.getElementById('engine-btn').addEventListener('click', toggleEngine);

    // Lock button
    document.getElementById('lock-btn').addEventListener('click', toggleLock);

    // Escape key to close
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape' && isDisplayVisible) {
            if (isExpanded) {
                document.getElementById('car-control-container').classList.remove('expanded');
                isExpanded = false;
            } else {
                closeDisplay();
            }
        }
    });

    // Click on info widget toggles expansion
    document.getElementById('info-display').addEventListener('click', () => {
        if (isDisplayVisible) {
            const container = document.getElementById('car-control-container');
            if (isExpanded) {
                container.classList.remove('expanded');
                isExpanded = false;
            } else {
                container.classList.add('expanded');
                isExpanded = true;
            }
        }
    });
});

// Communication with FiveM
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.type) {
        case 'showUI':
            showDisplay(data.vehicle);
            break;
        case 'hideUI':
            hideDisplay();
            break;
        case 'updateInfo':
            updateInfo(data.time, data.weather, data.isDay);
            break;
        case 'updateVehicle':
            updateVehicle(data.vehicle);
            break;
    }
});

// UI Functions
function showDisplay(vehicle) {
    isDisplayVisible = true;
    const container = document.getElementById('car-control-container');
    // expand the car control menu
    container.classList.add('expanded');
    isExpanded = true;
    if (vehicle) {
        updateVehicle(vehicle);
    }
}

function hideDisplay() {
    isDisplayVisible = false;
    const container = document.getElementById('car-control-container');
    // collapse the car control menu but keep widget visible
    container.classList.remove('expanded');
    isExpanded = false;
}

function updateInfo(time, weather, isDay) {
    if (time) {
        document.getElementById('time').textContent = time;
    }
    
    if (weather) {
        document.getElementById('weather').textContent = weather;
        
        // Update weather icon based on weather condition
        const weatherIcon = document.querySelector('.weather-display i');
        const norm = weather.toLowerCase().replace(/\s+/g, '-');
        switch (norm) {
            case 'clear':
            case 'extra-sunny':
                weatherIcon.className = 'fas fa-sun';
                break;
            case 'cloudy':
            case 'overcast':
                weatherIcon.className = 'fas fa-cloud';
                break;
            case 'rain':
                weatherIcon.className = 'fas fa-cloud-rain';
                break;
            case 'thunder':
                weatherIcon.className = 'fas fa-bolt';
                break;
            case 'foggy':
            case 'smog':
                weatherIcon.className = 'fas fa-smog';
                break;
            case 'snowy':
            case 'light-snow':
            case 'blizzard':
                weatherIcon.className = 'fas fa-snowflake';
                break;
            case 'clearing':
                weatherIcon.className = 'fas fa-cloud-sun';
                break;
            default:
                weatherIcon.className = 'fas fa-cloud-sun';
        }
    }
    
    // Update background class based on weather and day/night
    const infoDisplay = document.getElementById('info-display');
    const classes = Array.from(infoDisplay.classList);
    classes.forEach(cls => {
        if (cls.startsWith('weather-') || cls === 'day' || cls === 'night') {
            infoDisplay.classList.remove(cls);
        }
    });
    if (weather) {
        const normWeather = weather.toLowerCase().replace(/\s+/g, '-');
        infoDisplay.classList.add(`weather-${normWeather}`);
    }
    if (typeof isDay === 'boolean') {
        infoDisplay.classList.add(isDay ? 'day' : 'night');
    }
}

function updateVehicle(vehicle) {
    currentVehicle = vehicle;
    
    // Update door buttons
    if (vehicle.doors) {
        vehicle.doors.forEach(door => {
            const doorBtn = document.getElementById(`door-${door.id}`);
            if (doorBtn) {
                if (door.open) {
                    doorBtn.classList.add('open');
                } else {
                    doorBtn.classList.remove('open');
                }
            }
        });
    }
    
    // Update engine button
    const engineBtn = document.getElementById('engine-btn');
    if (vehicle.engine) {
        engineBtn.classList.add('on');
        engineBtn.querySelector('span').textContent = 'Engine On';
    } else {
        engineBtn.classList.remove('on');
        engineBtn.querySelector('span').textContent = 'Engine Off';
    }
    
    // Update lock button
    const lockBtn = document.getElementById('lock-btn');
    if (vehicle.locked) {
        lockBtn.classList.add('locked');
        lockBtn.querySelector('i').className = 'fas fa-lock';
        lockBtn.querySelector('span').textContent = 'Locked';
    } else {
        lockBtn.classList.remove('locked');
        lockBtn.querySelector('i').className = 'fas fa-unlock';
        lockBtn.querySelector('span').textContent = 'Unlocked';
    }
}

// Action Functions
function toggleDoor(doorIndex) {
    fetch('https://iq_carcontrol/toggleDoor', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            doorIndex: doorIndex
        })
    });
}

function changeSeat(seatIndex) {
    fetch('https://iq_carcontrol/changeSeat', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            seatIndex: seatIndex
        })
    });
}

function toggleEngine() {
    fetch('https://iq_carcontrol/toggleEngine', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function toggleLock() {
    fetch('https://iq_carcontrol/toggleLock', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function closeDisplay() {
    fetch('https://iq_carcontrol/close', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
} 