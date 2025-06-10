// -----------------------------------------
// Function to submit the form and display result in a table
async function submitForm(event) {
    event.preventDefault();
    document.getElementById('result').textContent = "";
    document.getElementById('table-container').textContent = "";
    const ip = document.getElementById('ip').value;
    var jsonData = [];

    // don't submit input with path or escape characters in the name, or any string terminators
    const pattern = /\\|\/|;|`|'|"|\.{2,}|\(|\)|<|>|\$|\?|!|&/;
    if (ip.match(pattern)) {
        document.getElementById('result').textContent = "Error: Hostname is not valid";
        return;
    }

    // submit the hostname parameter to the API
    const response = await fetch(`/api/hostname/${ip}`);
    jsonData = await response.json();
    // Check if the response status is not 200, and display an error message. Expecting the error returned from the API in a specific JSON payload - but if not display generic error.
    if (response.status != 200) {
        try {
            document.getElementById('result').textContent = "Error: " + jsonData.message;
            return;
        }
        catch {
            document.getElementById('result').textContent = "Error: Hostname is not valid";
            return;
        }
    }
    // if a 200 response code returned, display the results in a table
    else {
        document.getElementById('table-container').appendChild(generateTable(jsonData));
    }


}

// -----------------------------------------
// Function to generate a table from JSON data.
function generateTable(jsonData) {
    const table = document.createElement('table');
    const thead = document.createElement('thead');
    const tbody = document.createElement('tbody');

    // Create table header. Manually add Cloud Provider, Region, Service, Subnet headers
    const headerRow = document.createElement('tr');
    ['IP Address', 'Cloud Provider', 'Region', 'Service', 'Subnet'].forEach(key => {
        const th = document.createElement('th');
        th.textContent = key.charAt(0).toUpperCase() + key.slice(1);
        headerRow.appendChild(th);
    });
    thead.appendChild(headerRow);

    // Create table rows, Manually specify the order of the keys used to populate the table
    jsonData.forEach(item => {
        const row = document.createElement('tr');
        ['IPAddress', 'CloudProvider', 'Region', 'Service', 'Subnet'].forEach((key) => {
            const td = document.createElement('td');
            td.textContent = item[key.toString()];
            row.appendChild(td);
        });
        tbody.appendChild(row);
    });

    table.appendChild(thead);
    table.appendChild(tbody);
    return table;
}

// -----------------------------------------
// Increase the size of the input field based on size of the IP / Hostname entered
function adjustInputWidth(input) {
    // format text as lower case to make calculating width more consistent (or move to monospaced font?). Trim whitespace.
    input.value = input.value.toLocaleLowerCase().trim();
    // Calculate the new width of the .centered style based on the length of the input value
    const newWidth = Math.max((input.value.length * 17) + 10, 300); // Adjust the multiplier as needed
    const element = document.querySelector('.centered');
    element.style.width = `${newWidth}px`;
}

// -----------------------------------------
// Return the container build date as a string (read from text file created during container build)
async function GetContainerBuildDate() {
    try {
        const infoResponse = await fetch(`/api/info`);
        if (!infoResponse.ok) {
            return "unknown";
        }
        jsonInfoData = await infoResponse.json();
        return jsonInfoData.BuildDate;
    }
    catch {
        return "unknown";
    }
}

// -----------------------------------------
// Register listener on page load
window.onload = function () {
    // Dynamically adjust input box width based on text size 
    const inputBox = document.getElementById('ip');
    inputBox.addEventListener('input', function () {
        adjustInputWidth(inputBox);
    });
    // add container build date to page
    GetContainerBuildDate().then(buildDate => document.getElementById('containerbuilddate').textContent = `Container build date: ${buildDate}`);

    // Register listener for form submission
    document.getElementById('SubmitForm').addEventListener('submit', function(event) {
        submitForm(event);
    });
}