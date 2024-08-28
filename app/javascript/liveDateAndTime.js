console.log("Live Date and Time JS Connected");

function display_c() {
  const refresh = 1000; // Refresh rate in milliseconds
  setTimeout(display_ct, refresh);
}

function display_ct() {
  const x = new Date();
  document.getElementById('ct').innerHTML = x;
  display_c();
}

// Start the clock
display_ct();
