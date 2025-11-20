class Invoice < ApplicationRecord
  CENTS_PER_DOLLAR = 100

  has_many :payments, dependent: :destroy

  validates :invoice_total, presence: true, numericality: { only_integer: true, greater_than: 0 }
  before_validation :convert_invoice_total_to_cents, if: :invoice_total_changed?

  def fully_paid?
    amount_owed_cents <= 0
  end

  def amount_owed
    to_dollars(amount_owed_cents)
  end

  def record_payment(amount_paid, payment_method)
    return false unless amount_paid.positive?
    amount_in_cents = to_cents(amount_paid)

    result = transaction do
      lock!

      current_owed = amount_owed_cents
      # Prevent overpayment
      if amount_in_cents > current_owed
        errors.add(:base, "Payment amount ($#{amount_paid}) exceeds amount owed ($#{to_dollars(current_owed)})")
        raise ActiveRecord::Rollback
      end

      payments.create!(amount: amount_in_cents, raw_payment_method: payment_method)
    end

    result || false
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.record.errors.full_messages.join(", "))
    false
  end

  private

  def amount_owed_cents
    invoice_total - payments.sum(:amount)
  end

  def to_cents(dollars)
    (dollars.to_f * CENTS_PER_DOLLAR).round
  end

  def to_dollars(cents)
    (cents.to_f / CENTS_PER_DOLLAR).round(2)
  end

  def convert_invoice_total_to_cents
    return if invoice_total.nil?
    self.invoice_total = (invoice_total.to_f * 100).round
  end
end
