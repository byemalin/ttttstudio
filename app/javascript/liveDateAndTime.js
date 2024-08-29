document.addEventListener('DOMContentLoaded', function() {
  console.log("DOMContentLoaded")
  console.log("Live Date and Time JS Connected");

  const display_c = () => {
    const refresh = 1000; // Refresh rate in milliseconds
    setTimeout(display_ct, refresh);
  }

  const display_ct = () => {
    const x = new Date();
    const ctElement = document.getElementById('ct');
    if (ctElement) {
      ctElement.innerHTML = x;
      display_c();
    } else {
      console.error("Element with ID 'ct' not found.");
    }
  }

  // Start the clock
  display_ct();

});
