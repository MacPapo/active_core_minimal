import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search-form"
export default class extends Controller {
	connect() {
		console.log("Form Search Connected!")
	}

	search() {
		clearTimeout(this.timeout)

		this.timeout = setTimeout(() => {
			this.element.requestSubmit()
		}, 300)
	}

	submit() {
		this.element.requestSubmit()
	}
}
