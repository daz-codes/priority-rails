import "@hotwired/turbo-rails";
import "controllers";

import { get, post, patch, put, destroy } from "@rails/request.js";

function yozu() {
  const METHODS = { get, post, patch, put, delete: destroy };
  const SELECTOR = Object.keys(METHODS)
    .map((m) => `[yozu-${m}]`)
    .join(",");

  document.querySelectorAll(SELECTOR).forEach((el) => request(el));

  function request(el) {
    const methodAttr = Object.keys(METHODS).find((m) =>
      el.hasAttribute(`yozu-${m}`),
    );
    const url = el.getAttribute(`yozu-${methodAttr}`);

    el.addEventListener("click", async (e) => {
      const scope = { event: e, target: e.target, checked: e.target.checked };
      let body;
      const rawParams = el.getAttribute("yozu-params");
      if (rawParams) {
        try {
          body = JSON.stringify(
            new Function(...Object.keys(scope), `return (${rawParams})`)(
              ...Object.values(scope),
            ),
          );
        } catch (err) {
          console.error("Error evaluating yozu-params:", err);
        }
      }

      try {
        const options =
          ["post", "patch", "delete"].includes(methodAttr) && body
            ? { body }
            : {};

        const response = await METHODS[methodAttr](url, options);

        const contentType = response.headers.get("content-type") || "";

        let data;
        if (contentType.includes("application/json")) {
          data = await response.json();
        } else {
          data = await response.text();
        }

        // You can process `data` or dispatch events here if you want
      } catch (err) {
        console.error("yozu request error:", err);
      }
    });
  }
}

yozu();
