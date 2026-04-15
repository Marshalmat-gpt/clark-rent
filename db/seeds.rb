# db/seeds.rb
# Données de test pour valider le flow agent sur Saint-Brieuc (ville pilote Clark)
# Usage : rails db:seed

puts "🌱 Seeding Clark Rent — Saint-Brieuc pilot data..."

# ── Propriétaire ─────────────────────────────────────────────────────────────

owner = User.find_or_create_by!(email: 'owner@clark-rent.fr') do |u|
  u.first_name    = 'Thomas'
  u.last_name     = 'Dupont'
  u.password      = 'password123'
  u.role          = 'owner'
  u.phone         = '+33612345678'
end
puts "  ✓ Owner: #{owner.full_name}"

# ── Locataires ───────────────────────────────────────────────────────────────

tenant1 = User.find_or_create_by!(email: 'alice@example.com') do |u|
  u.first_name = 'Alice'
  u.last_name  = 'Martin'
  u.password   = 'password123'
  u.role       = 'tenant'
  u.phone      = '+33698765432'
end

tenant2 = User.find_or_create_by!(email: 'bob@example.com') do |u|
  u.first_name = 'Bob'
  u.last_name  = 'Leroy'
  u.password   = 'password123'
  u.role       = 'tenant'
  u.phone      = '+33611223344'
end

tenant3 = User.find_or_create_by!(email: 'carla@example.com') do |u|
  u.first_name = 'Carla'
  u.last_name  = 'Nguyen'
  u.password   = 'password123'
  u.role       = 'tenant'
  u.phone      = '+33655443322'
end

puts "  ✓ Tenants: #{[tenant1, tenant2, tenant3].map(&:full_name).join(', ')}"

# ── Propriété 1 — Colocation 3 chambres ──────────────────────────────────────

coloc = Property.find_or_create_by!(address: '12 Rue de la Liberté', city: 'Saint-Brieuc') do |p|
  p.owner         = owner
  p.zipcode       = '22000'
  p.property_type = 4       # T3
  p.furnished     = true
  p.area          = 75.0
  p.floor         = 2
  p.energy        = 'C'
  p.rent_type     = 'shared'
end
puts "  ✓ Property 1: #{coloc.formatted_address}"

lease_coloc = PropertyLease.find_or_create_by!(property: coloc, status: 'open') do |l|
  l.name           = 'Bail colocation — Liberté'
  l.amount         = 1050.0   # 3 x 350€
  l.expense_amount = 150.0    # 3 x 50€
  l.start_date     = Date.new(2024, 9, 1)
  l.end_date       = Date.new(2025, 8, 31)
  l.irl_reference  = 140.59
end

# Candidatures approuvées pour les 3 colocataires
[tenant1, tenant2, tenant3].each do |t|
  LeaseApplication.find_or_create_by!(property_lease: lease_coloc, applicant: t) do |a|
    a.status = 'approved'
    a.description = "Candidature approuvée — colocation Liberté"
  end
end

# Historique de paiements (6 mois)
6.times do |i|
  month = Date.new(2025, 1, 1) >> i
  RentPayment.find_or_create_by!(lease: lease_coloc, due_date: month) do |p|
    p.tenant         = tenant1
    p.amount         = 1050.0
    p.expense_amount = 150.0
    p.status         = i < 5 ? 'paid' : 'pending'
    p.paid_at        = i < 5 ? month + 2 : nil
    p.payment_method = 'virement'
  end
end

puts "  ✓ Lease + 6 payments created for coloc"

# ── Propriété 2 — T3 avec bail expirant bientôt ──────────────────────────────

t3 = Property.find_or_create_by!(address: '8 Rue Balzac', city: 'Saint-Brieuc') do |p|
  p.owner         = owner
  p.zipcode       = '22000'
  p.property_type = 4       # T3
  p.furnished     = false
  p.area          = 68.0
  p.floor         = 1
  p.energy        = 'D'
  p.rent_type     = 'whole'
end
puts "  ✓ Property 2: #{t3.formatted_address}"

lease_t3 = PropertyLease.find_or_create_by!(property: t3, status: 'open') do |l|
  l.name           = 'Bail T3 — Balzac'
  l.amount         = 620.0
  l.expense_amount = 80.0
  l.start_date     = Date.new(2023, 6, 1)
  l.end_date       = Date.today + 45   # expire dans 45 jours → alerte agent
  l.irl_reference  = 138.12
end

LeaseApplication.find_or_create_by!(property_lease: lease_t3, applicant: tenant2) do |a|
  a.status      = 'approved'
  a.description = "Candidature approuvée — T3 Balzac"
end

puts "  ✓ Lease T3 expiring in 45 days (agent alert trigger)"

# ── Ticket ouvert — Chauffage urgent ─────────────────────────────────────────

Ticket.find_or_create_by!(property: coloc, tenant: tenant1, category: 'chauffage') do |t|
  t.description = "La chaudière collective ne fonctionne plus depuis ce matin. Pas d'eau chaude ni de chauffage."
  t.priority    = 'urgent'
  t.status      = 'open'
end

puts "  ✓ Urgent ticket: chauffage on coloc"

# ── Résumé ───────────────────────────────────────────────────────────────────

puts ""
puts "✅ Seed complete — Clark Saint-Brieuc pilot data ready"
puts ""
puts "  Test agent owner:"
puts "    POST /api/v1/sessions { email: 'owner@clark-rent.fr', password: 'password123' }"
puts ""
puts "  Test agent tenant:"
puts "    POST /api/v1/sessions { email: 'alice@example.com', password: 'password123' }"
puts ""
puts "  Console test:"
puts "    user = User.find_by(email: 'alice@example.com')"
puts "    ClarkAgent::Orchestrator.run("
puts "      system:  ClarkAgent::SystemPrompt.build(user: user, role: 'tenant'),"
puts "      history: [],"
puts "      message: \"Ma chaudière est tombée en panne, que faire ?\","
puts "      user:    user,"
puts "      role:    'tenant'"
puts "    )"
