document.addEventListener("turbo:frame-missing", (event) => {
    if (event.target.id === "modal") {
        const response = event.detail.response;
        event.preventDefault();

        if (response.ok && response.status < 400) {
            event.detail.visit(response.url, { action: "replace" });
        } else {
            event.target.innerHTML = `
        <div class="bg-red-100 rounded-md py-2 px-4 text-red-800 my-4">
          <p class="text-red-700 text-sm">
            An error occurred while loading the modal. Please try again later.
          </p>
        </div>`;
        }
    }
});
