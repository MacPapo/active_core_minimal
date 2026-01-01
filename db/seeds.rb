admin = User.create!(
  username: "admin",
  first_name: "Mario", last_name: "Capo",
  email_address: "admin@kento.it",
  password: "password",
  role: :admin
)

puts "✅ SEED COMPLETATO CON SUCCESSO!"
puts "-------------------------------------------"
puts "Credenziali Staff:"
puts "Username: admin / Password: password"
puts "cambiare la password il prima possibile"
puts "-------------------------------------------"
