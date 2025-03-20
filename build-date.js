// Create a file containing the build date of the solution. 
// The file will be overwritten when a container is built, so this is only referenced if running from source instead of a container.

const fs = require('fs');
const path = require('path');

// Get today's date
const today = new Date();
const options = { day: '2-digit', month: 'long', year: 'numeric' };
const dateString = today.toLocaleDateString('en-US', options); // Format: DD-Month-YYYY


// Write the date to the file
try {
    // Define the file path
    const filePath = path.join(__dirname, './release/build_date.txt');
    fs.writeFile(filePath, dateString, (err) => {
    });
}
catch (err) {
    console.error('Error writing to file', err);
}
