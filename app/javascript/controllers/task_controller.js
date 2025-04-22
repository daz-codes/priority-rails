import { Controller } from "@hotwired/stimulus";
import { patch } from "@rails/request.js";

export default class extends Controller {
  static values = { url: String };

  async toggle(event) {
    console.log("toggle!")
    const checked = event.target.checked; // Get new checkbox state
    try {
      const response = await patch(this.urlValue, {
        body: JSON.stringify({ task: { completed: checked } }),
        headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }
      });
      
      if (!response.ok) {
        throw new Error('Request failed');
      }

      // Handle the response if needed, e.g. updating the UI
    } catch (error) {
      console.error('Error during patch request:', error);
      // Optionally, notify the user or take action on error
    }
  }
}