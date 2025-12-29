import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	static targets = [
		"productSelect", "memberSelect", "amountInput", "totalDisplay",
		"startDateInput", "startDateDisplay", "endDateDisplay", "statusDisplay"
	]

	connect() {
		this.updateTotalDisplay()
	}

	// Chiamata quando cambia Socio o Prodotto (Select)
	refreshData() {
		this.updatePrice()
		this.fetchRenewalDates() // Chiama il server per la "prima proposta"
	}

	// Chiamata quando l'utente cambia manualmente la data (Input)
	recalculateEndDate() {
		const startDateVal = this.startDateInputTarget.value
		const selectedOption = this.productSelectTarget.selectedOptions[0]

		// Se non c'è data o prodotto, usciamo
		if (!startDateVal || !selectedOption) return

		// 1. Aggiorniamo subito il display della data inizio
		if (this.hasStartDateDisplayTarget) {
			this.startDateDisplayTarget.textContent = this.formatDateIT(startDateVal)
		}

		// 2. Calcoliamo la fine basandoci sulla durata (Client side, niente server!)
		const durationDays = parseInt(selectedOption.dataset.duration)

		if (!isNaN(durationDays) && durationDays > 0) {
			const startDate = new Date(startDateVal)
			// Logica: Data Fine = Inizio + Durata - 1 giorno
			// (Es. Inizio 1 Gen, Durata 30gg -> Fine 30 Gen, non 31)
			const endDate = new Date(startDate)
			endDate.setDate(startDate.getDate() + durationDays - 1)

			// Aggiorniamo il display scadenza
			if (this.hasEndDateDisplayTarget) {
				// Convertiamo in YYYY-MM-DD per passarlo al formattatore
				const endString = endDate.toISOString().split('T')[0]
				this.endDateDisplayTarget.textContent = this.formatDateIT(endString)
			}

			this.statusDisplayTarget.textContent = "Data modificata manualmente"
			this.statusDisplayTarget.className = "text-center text-xs text-warning font-bold"
		}
	}

	// --- LE ALTRE FUNZIONI (Price, Total) RIMANGONO UGUALI ---
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

	// --- FETCH DAL SERVER (Rimane uguale, setta la proposta iniziale) ---
	async fetchRenewalDates() {
		const memberId = this.memberSelectTarget.value
		const productId = this.productSelectTarget.value

		if (!memberId || !productId) return

		this.statusDisplayTarget.textContent = "Calcolo..."
		const url = `/members/${memberId}/renewal_info?product_id=${productId}`

		try {
			const response = await fetch(url, { headers: { "Accept": "application/json" } })
			if (response.ok) {
				const data = await response.json()

				// Aggiorna Input
				if (this.hasStartDateInputTarget && data.start_date) {
					this.startDateInputTarget.value = data.start_date
				}
				// Aggiorna Display
				if (this.hasStartDateDisplayTarget) this.startDateDisplayTarget.textContent = this.formatDateIT(data.start_date)
				if (this.hasEndDateDisplayTarget) this.endDateDisplayTarget.textContent = this.formatDateIT(data.end_date)

				this.statusDisplayTarget.textContent = "Periodo calcolato automaticamente"
				this.statusDisplayTarget.className = "text-center text-xs opacity-50 italic text-success"
			}
		} catch (e) { console.error(e) }
	}

	formatDateIT(dateString) {
		if (!dateString) return "---"
		const [year, month, day] = dateString.split("-")
		return `${day}/${month}/${year}`
	}
}
