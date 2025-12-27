import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	connect() {
	}

	close(event) {
		event.preventDefault()

		const modalFrame = document.getElementById("modal")

		if (modalFrame) {
			modalFrame.removeAttribute("src")
			modalFrame.innerHTML = ""
		}
	}
}
