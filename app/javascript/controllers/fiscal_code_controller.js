import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	static targets = ["code", "birthDate"]

	// Scatta ogni volta che scrivi nel campo CF
	autofill() {
		this.codeTarget.value = this.codeTarget.value.toUpperCase()
		const cf = this.codeTarget.value

		// Il CF deve avere almeno 11 caratteri per contenere la data
		if (cf.length < 11) return

		// Estraiamo i pezzi
		const yearPart = cf.substring(6, 8)  // "80"
		const monthChar = cf.substring(8, 9) // "A"
		const dayPart = cf.substring(9, 11)  // "01" o "41"

		// Decodifica Mese
		const months = { 'A': '01', 'B': '02', 'C': '03', 'D': '04', 'E': '05', 'H': '06', 'L': '07', 'M': '08', 'P': '09', 'R': '10', 'S': '11', 'T': '12' }
		const month = months[monthChar]

		if (!month) return // Carattere mese non valido

		// Decodifica Giorno (Gestione Sesso)
		let day = parseInt(dayPart)
		if (day > 40) day -= 40 // Se è donna (es. 45), diventa 5

		// Formatta giorno a due cifre (es. 5 -> "05")
		const dayString = day.toString().padStart(2, '0')

		// Decodifica Anno (Stima 1900 vs 2000)
		// Logica semplice: se l'anno estratto è > dell'anno corrente (es 24), allora è 1900.
		// Altrimenti assumiamo 2000 (per i nati dopo il 2000).
		const currentYearTwoDigits = new Date().getFullYear() % 100
		let fullYear = (parseInt(yearPart) > currentYearTwoDigits) ? `19${yearPart}` : `20${yearPart}`

		// SCRIVI NEL CAMPO DATA (Formato YYYY-MM-DD standard HTML)
		const fullDate = `${fullYear}-${month}-${dayString}`
		this.birthDateTarget.value = fullDate

		// Feedback visivo (opzionale): Fai lampeggiare il bordo verde
		this.birthDateTarget.classList.add("border-success")
		setTimeout(() => this.birthDateTarget.classList.remove("border-success"), 1000)
	}
}
