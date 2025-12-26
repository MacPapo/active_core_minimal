# db/seeds.rb

puts "🌱 Kento Seeding: Inizio pulizia e popolamento..."

# 1. PULIZIA (Ordine inverso per le Foreign Keys)
# Disattiviamo i log per non intasare la console durante la distruzione
ActiveRecord::Base.logger.silence do
  ActivityLog.delete_all
  AccessLog.delete_all
  Subscription.delete_all
  Sale.delete_all
  Feedback.delete_all
  ProductDiscipline.delete_all
  Product.delete_all
  Discipline.delete_all
  Member.delete_all
  Session.delete_all
  User.delete_all
  ReceiptCounter.delete_all
end

puts "🧹 Database pulito."

# 2. STAFF
puts "👥 Creazione Staff..."
password = "password" # Default per tutti

admin = User.create!(
  username: "admin",
  first_name: "Mario", last_name: "Capo",
  email_address: "admin@kento.it",
  password: password, password_confirmation: password,
  role: :admin
)

staff = User.create!(
  username: "staff",
  first_name: "Luigi", last_name: "Reception",
  email_address: "info@kento.it",
  password: password, password_confirmation: password,
  role: :staff
)

# 3. DISCIPLINE & PRODOTTI
puts "🏷️  Creazione Listino..."

# Discipline
yoga = Discipline.create!(name: "Yoga")
pesi = Discipline.create!(name: "Sala Pesi")
pilates = Discipline.create!(name: "Pilates")

# Prodotti ASSOCIATIVI (Tessere)
quota_2025 = Product.create!(
  name: "Quota Associativa 2025",
  price_cents: 3000, # 30.00€
  duration_days: 365,
  accounting_category: :associative
)

# Prodotti ISTITUZIONALI (Corsi)
yoga_mensile = Product.create!(
  name: "Yoga Mensile",
  price_cents: 5000, # 50.00€
  duration_days: 30,
  accounting_category: :institutional
)
yoga_mensile.disciplines << yoga

pesi_annuale = Product.create!(
  name: "Sala Pesi Annuale",
  price_cents: 40000, # 400.00€
  duration_days: 365,
  accounting_category: :institutional
)
pesi_annuale.disciplines << pesi

pacchetto_open = Product.create!(
  name: "Pacchetto Open (Yoga + Pesi)",
  price_cents: 6000,
  duration_days: 30,
  accounting_category: :institutional
)
pacchetto_open.disciplines << [ yoga, pesi ]

# 4. SOCI (MEMBERS)
puts "users Creazione Soci..."

# Helper per generare CF finti
def fake_fiscal_code
  chars = [ ('A'..'Z'), ('0'..'9') ].map(&:to_a).flatten
  (0...16).map { chars[rand(chars.length)] }.join
end

# Socio PERFETTO (Alice)
alice = Member.create!(
  first_name: "Alice", last_name: "Attiva",
  fiscal_code: fake_fiscal_code,
  birth_date: "1990-01-01",
  email_address: "alice@test.com",
  medical_certificate_expiry: 6.months.from_now
)

# Socio SCADUTO (Bob)
bob = Member.create!(
  first_name: "Bob", last_name: "Scaduto",
  fiscal_code: fake_fiscal_code,
  birth_date: "1985-05-05",
  email_address: "bob@test.com",
  medical_certificate_expiry: 6.months.from_now
)

# Socio NUOVO (Carlo - Senza certificato né tessera)
carlo = Member.create!(
  first_name: "Carlo", last_name: "Nuovo",
  fiscal_code: fake_fiscal_code,
  birth_date: "2000-10-10",
  email_address: "carlo@test.com",
  medical_certificate_expiry: nil
)

# 5. SIMULAZIONE VENDITE (SALES & SUBSCRIPTIONS)
puts "💰 Simulazione Vendite e Cassa..."

# A. Alice: Compra Tessera e Yoga Mese Scorso (Oggi rinnova)
# Vendita passata (35 giorni fa)
Sale.create!(
  member: alice, user: admin, product: quota_2025,
  sold_on: 35.days.ago, payment_method: :cash,
  subscription_attributes: { member: alice, product: quota_2025 }
)
Sale.create!(
  member: alice, user: admin, product: yoga_mensile,
  sold_on: 35.days.ago, payment_method: :cash,
  subscription_attributes: { member: alice, product: yoga_mensile }
)

# B. Bob: Aveva un annuale pesi scaduto l'anno scorso
Sale.create!(
  member: bob, user: staff, product: quota_2025, # Tessera vecchia (simuliamo rinnovo sotto)
  sold_on: 13.months.ago, payment_method: :cash,
  subscription_attributes: { member: bob, product: quota_2025 }
)
# Bob non ha tessera attiva OGGI, quindi non può comprare corsi finché non rinnova la tessera.

# 6. MOVIMENTI CASSA DI OGGI (Per testare DailyCash)
puts "💵  Riempimento cassa odierna..."

today = Date.current

# MATTINA (Ore 10:00)
# Alice rinnova il mensile Yoga (Smart Renewal: Continuità)
Time.use_zone("Rome") do
  date_time = today.beginning_of_day + 10.hours

  # Usiamo 'travel_to' logico impostando created_at manuale se possibile,
  # ma Rails sovrascrive created_at. Per i seed, forziamo il timestamp.

  sale_alice = Sale.create!(
    member: alice, user: staff, product: yoga_mensile,
    sold_on: today,
    payment_method: :cash,
    subscription_attributes: { member: alice, product: yoga_mensile }
  )
  sale_alice.update_columns(created_at: date_time, updated_at: date_time)
end

# POMERIGGIO (Ore 16:00)
# Carlo si iscrive: Tessera + Open
Time.use_zone("Rome") do
  date_time = today.beginning_of_day + 16.hours

  # 1. Carlo paga la Quota (30€)
  sale_carlo_tessera = Sale.create!(
    member: carlo, user: staff, product: quota_2025,
    sold_on: today, payment_method: :cash,
    subscription_attributes: { member: carlo, product: quota_2025 }
  )
  sale_carlo_tessera.update_columns(created_at: date_time, updated_at: date_time)

  # 2. Carlo paga il Pacchetto Open (60€)
  # Nota: Ora PUÒ farlo perché ha la tessera attiva (step 1)
  sale_carlo_corso = Sale.create!(
    member: carlo, user: staff, product: pacchetto_open,
    sold_on: today, payment_method: :credit_card, # Pagato col POS!
    subscription_attributes: { member: carlo, product: pacchetto_open }
  )
  sale_carlo_corso.update_columns(created_at: date_time + 5.minutes, updated_at: date_time + 5.minutes)
end

# 7. LOG ACCESSI (Check-in)
puts "🔑 Simulazione Ingressi..."

# Alice entra oggi a Yoga
AccessLog.create!(
  member: alice,
  subscription: alice.subscriptions.active.where(product: yoga_mensile).first,
  checkin_by_user: staff,
  entered_at: Time.now
)

puts "✅ SEED COMPLETATO CON SUCCESSO!"
puts "-------------------------------------------"
puts "Credenziali Staff:"
puts "Username: staff / Password: password"
puts "Username: admin / Password: password"
puts "-------------------------------------------"
