class Payment < ApplicationRecord
  PAYMENT_METHODS = { cash: 1, check: 2, charge: 3 }.freeze

  belongs_to :invoice
  attr_accessor :raw_payment_method

  validates :payment_method_id, inclusion: { in: PAYMENT_METHODS.values, message: "must be valid" }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :payment_method_must_be_valid

  before_validation :set_payment_method_id, if: -> { raw_payment_method.present? }

  def payment_method
    PAYMENT_METHODS.key(payment_method_id)
  end

  private

  def set_payment_method_id
    return if raw_payment_method.blank?
    normalized = raw_payment_method.to_s.strip.downcase.to_sym
    self.raw_payment_method = normalized
    self.payment_method_id = PAYMENT_METHODS[normalized]
  end

  def payment_method_must_be_valid
    return unless raw_payment_method
    unless PAYMENT_METHODS.key?(raw_payment_method.to_sym)
      errors.add(:raw_payment_method, "must be cash, check, or charge")
    end
  end
end
