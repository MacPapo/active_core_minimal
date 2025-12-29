import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	static targets = [
		"productSelect", "memberSelect", "amountInput", "totalDisplay",
		"startDateInput", "startDateDisplay", "endDateDisplay", "statusDisplay"
	]

	connect() {
		this.updateTotalDisplay()

		if (this.hasMemberSelectTarget && this.memberSelectTarget.value &&
			this.hasProductSelectTarget && this.productSelectTarget.value) {

			this.refreshData()
		}
	}

	refreshData(event) {
		// Se non ho selezionato nulla, esco
		if (!this.productSelectTarget.value || !this.memberSelectTarget.value) return;

		this.updatePrice()
		this.fetchRenewalDates(event)
	}

	updatePrice() {
		const selectedOption = this.productSelectTarget.selectedOptions[0]
		if (!selectedOption) return

		const price = selectedOption.dataset.price
		if (price) {
			this.amountInputTarget.value = parseFloat(price).toFixed(2).replace('.', ',')
			this.updateTotalDisplay()
		}
	}

	updateTotalDisplay() {
		const value = this.amountInputTarget.value.replace(',', '.')
		const number = parseFloat(value)
		this.totalDisplayTarget.textContent = isNaN(number) ? "0,00" : number.toFixed(2).replace('.', ',')
	}

	async fetchRenewalDates(event) {
		const memberId = this.memberSelectTarget.value
		const productId = this.productSelectTarget.value

		// La data che TU hai scritto a mano
		const currentInputVal = this.startDateInputTarget.value

		if (!memberId || !productId) return

		// Capiamo se sei stato TU a scatenare l'evento modificando la data
		const userChangedDate = (event && event.target === this.startDateInputTarget)

		this.statusDisplayTarget.textContent = "Calcolo..."
		this.statusDisplayTarget.className = "text-center text-xs opacity-50 italic"

		let url = `/members/${memberId}/renewal_info?product_id=${productId}`

		// Inviamo sempre la tua data corrente come riferimento
		if (currentInputVal) {
			url += `&ref_date=${currentInputVal}`
		}

		try {
			const response = await fetch(url, { headers: { "Accept": "application/json" } })
			if (response.ok) {
				const data = await response.json()

				// --- ZONA FIX ---

				if (userChangedDate) {
					// 🛑 STOP! L'hai cambiata tu. 
					// IGNORIAMO data.start_date del server.
					// Non tocchiamo this.startDateInputTarget.value

					// Aggiorniamo solo il display testuale per coerenza visiva
					if (this.hasStartDateDisplayTarget) {
						this.startDateDisplayTarget.textContent = this.formatDateIT(currentInputVal)
					}
				} else {
					// ✅ OK. Hai cambiato prodotto o socio.
					// Qui accettiamo il suggerimento del server.
					if (this.hasStartDateInputTarget && data.start_date) {
						this.startDateInputTarget.value = data.start_date
					}
					if (this.hasStartDateDisplayTarget) {
						this.startDateDisplayTarget.textContent = this.formatDateIT(data.start_date)
					}
				}

				// La data di FINE invece ci serve sempre dal server (perché calcola la durata)
				if (this.hasEndDateDisplayTarget) {
					this.endDateDisplayTarget.textContent = this.formatDateIT(data.end_date)
				}

				this.statusDisplayTarget.textContent = "Aggiornato"
				this.statusDisplayTarget.className = "text-center text-xs text-success font-bold"
			}
		} catch (e) {
			console.error(e)
			this.statusDisplayTarget.textContent = "Errore"
		}
	}

	formatDateIT(dateString) {
		if (!dateString) return "---"
		const [year, month, day] = dateString.split("-")
		return `${day}/${month}/${year}`
	}
}
