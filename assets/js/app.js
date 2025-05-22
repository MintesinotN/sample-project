// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import html2pdf from 'html2pdf.js';

// Add this after your LiveSocket initialization
document.addEventListener('click', (e) => {
  if (e.target.id === 'export-pdf') {
    const element = document.getElementById('rendered-output');
    const opt = {
      margin: 10,
      filename: 'markdown-export.pdf',
      image: { type: 'jpeg', quality: 0.98 },
      html2canvas: { scale: 2 },
      jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
    };
    
    html2pdf().from(element).set(opt).save();
  }
});


const CopyButton = {
  mounted() {
    this.el.addEventListener("click", () => {
      // Get the HTML content
      const htmlContent = document.getElementById("rendered-output").innerHTML;
      
      // Create a temporary element to hold the HTML
      const tempElement = document.createElement("div");
      tempElement.innerHTML = htmlContent;
      document.body.appendChild(tempElement);
      
      // Select the content
      const range = document.createRange();
      range.selectNode(tempElement);
      window.getSelection().removeAllRanges();
      window.getSelection().addRange(range);
      
      // Copy the content
      try {
        document.execCommand("copy");
        this.el.querySelector("span").textContent = "✓ Copied!";
        
        // Reset after 2 seconds
        setTimeout(() => {
          this.el.querySelector("span").textContent = "Copy";
          this.pushEvent("reset_copy", {});
        }, 2000);
      } catch (err) {
        console.error("Failed to copy:", err);
      }
      
      // Clean up
      window.getSelection().removeAllRanges();
      document.body.removeChild(tempElement);
    });
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {CopyButton},
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()


window.addEventListener("phx:download-pdf", (e) => {
  const {content, filename} = e.detail;
  
  // Convert base64 to binary
  const binaryString = atob(content);
  const bytes = new Uint8Array(binaryString.length);
  
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  
  // Create blob and download
  const blob = new Blob([bytes], {type: "application/pdf"});
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  link.style.display = "none";
  
  document.body.appendChild(link);
  link.click();
  
  // Cleanup
  setTimeout(() => {
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
  }, 100);
});


// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

