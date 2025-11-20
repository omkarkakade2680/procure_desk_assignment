# Refactor this Ruby on Rails class based on the mistakes and opportunities you see.
# There's no right or wrong answer, but there's plenty of room for improvement.
# Correct mistakes or logic errors.Improve readability. Handle errors gracefully.
# Make it more Ruby-like. Finally, add a few paragraphs explaining why you decided
# to make the changes you did.

# Assume Ruby 3.x and Rails 7.x

# Overview:
# This is a class for handling simplified invoices (requests for payment) 
# and payments. While there's room to expand the functionality, the classes have
# been kept simplified to reduce the scope of this effort.
# 1. Invoices can have multiple payments and can be partially paid.
# 2. Payments can be in the form of cash, check, or charge/credit card.
# 3. User-facing interactions and values are dollar amounts, but all currency 
#    values are transparently stored as pennies in the database.

# Data Model
# invoice:
#   id: integer
#   invoice_total: integer (in pennies)
#   created_at: datetime
#   updated_at: datetime
# payment:
#   id: integer
#   invoice_id: integer
#   payment_method_id: integer 
#   amount: integer (in pennies)
#   created_at: datetime
#   updated_at: datetime

# Primary Example Code:
# invoice = Invoice.create({invoice_total: 200.00})
# invoice.record_payment(100.00, :charge)

class Invoice
  # We expect invoices to be created in dollars as it's more comfortable for 
  # humans to work with, so we need to translate the dollar amount to pennies
  # before we create the invoice
  before_create :translate_invoice_total_to_cents

  attr_accessible :invoice_total
  
  has_many :payments

  # Return true or false for whether the invoice has been paid
  def fully_paid?
    amount_owed != 0
  end

  # Return the remaining amount owed for the invoice in dolllars and cents
  def amount_owed
    self.invoice_total - payments.sum(:amount_paid)
  end

  # Accepts payment amounts (in dollars and cents) and payment method and 
  # records that payment against the invoice
  def record_payment(amount_paid, payment_method)
    payments.create({amount: (amount_paid * 100).to_i, raw_payment_method: payment_method})
  end

  private

  # Presumes that invoice_total was provided in dollars and translates to cents
  # before saving
  def translate_invoice_total_to_cents
    self.invoice_total * 100
  end
end

class Payment
  METHODS = { cash: 1, check: 2, charge: 3 }

  # Since external methods pass in a raw_payment_method, we need to set the ID
  # value for storing in the database
  before_create :set_payment_method_id

  has_one :invoice

  attr_accessor :raw_payment_method
  attr_accessible :raw_payment_method, :amount

  validates :payment_method_id, inclusion: { in: [1, 2, 3] }, message: "is wrong"
  validates :payment_method_id, :amount, presence: true

  # Returns a symbol of the payment method based on the payment_method_id value
  def payment_method
    METHODS[payment_method_id]
  end

  # Set the payment_method_id value from the raw_payment_method.
  def set_payment_method_id
    self.payment_method_id = METHODS.value(raw_payment_method)
  end

  # Returns true or false based on whether the provided payment method is one of
  # our acceptable methods
  def valid_payment_method?
    [:cash, :check, :charge].include?(raw_payment_method)
  end
end
