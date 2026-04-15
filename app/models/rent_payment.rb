class RentPayment < ApplicationRecord
  belongs_to :lease,  class_name: 'PropertyLease', foreign_key: :lease_id
  belongs_to :tenant, class_name: 'User'

  has_one_attached :receipt  # PDF quittance stocké sur S3

  STATUSES         = %w[pending paid late disputed].freeze
  PAYMENT_METHODS  = %w[virement prelevement cheque especes].freeze

  validates :amount,   presence: true, numericality: { greater_than: 0 }
  validates :status,   inclusion: { in: STATUSES }
  validates :due_date, presence: true

  # ── Scopes ────────────────────────────────────────────────────────────────

  scope :paid,    -> { where(status: 'paid') }
  scope :pending, -> { where(status: 'pending') }
  scope :late,    -> { where(status: 'late') }
  scope :for_month, ->(date) { where(due_date: date.beginning_of_month..date.end_of_month) }
  scope :recent,  -> { order(due_date: :desc) }

  # ── Callbacks ─────────────────────────────────────────────────────────────

  before_save :check_lateness

  # ── Méthodes ──────────────────────────────────────────────────────────────

  # Marque le paiement comme reçu
  def mark_as_paid!(method: nil)
    update!(
      status:         'paid',
      paid_at:        Date.today,
      payment_method: method
    )
  end

  # Total TTC (loyer + charges)
  def total
    amount + (expense_amount || 0)
  end

  # Nombre de jours de retard
  def days_late
    return 0 unless late? && due_date
    (Date.today - due_date).to_i
  end

  def late?
    status == 'late'
  end

  def paid?
    status == 'paid'
  end

  # ── Génération automatique des paiements mensuels ─────────────────────────

  # Appelé lors de l'ouverture d'un bail pour pré-créer les échéances
  def self.generate_for_lease(lease:, months: 12)
    start_date = lease.start_date || Date.today

    months.times.map do |i|
      due = start_date >> i  # >> = décale d'un mois
      due = due.change(day: 1)  # toujours le 1er du mois

      find_or_create_by!(lease: lease, due_date: due) do |p|
        p.tenant         = lease.tenant
        p.amount         = lease.amount
        p.expense_amount = lease.expense_amount || 0
        p.status         = 'pending'
      end
    end
  end

  private

  def check_lateness
    return unless status == 'pending' && due_date
    self.status = 'late' if due_date < Date.today
  end
end
