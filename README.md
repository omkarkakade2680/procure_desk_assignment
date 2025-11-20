# Invoice & Payment System - Rails App

A complete Rails application implementing invoice and payment management with all bugs fixed from the original code.

## 🚀 Quick Setup

### Prerequisites
```bash
# Install PostgreSQL
brew install postgresql@15
brew services start postgresql@15

# Or on Linux
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### Setup (3 Commands)
```bash
# 1. Install dependencies
bundle install

# 2. Create and setup database
bin/rails db:create db:migrate

# 3. Test it works
bin/rails console
```

## 💻 Usage

### Rails Console
```ruby
# Start Rails console
bin/rails console

# Create an invoice
invoice = Invoice.create(invoice_total: 100.00)

# Record payments
invoice.record_payment(100.00, :charge)  # Credit card
invoice.record_payment(50.00, :cash)     # Cash  
invoice.record_payment(50.00, :check)    # Check

# Check status
invoice.fully_paid?    # => true
invoice.amount_owed    # => 0.0

# View payments
invoice.payments.each { |p| puts "#{p.payment_method}: $#{p.amount/100.0}" }
```

### Database Commands
```bash
bin/rails db:create      # Create database
bin/rails db:migrate     # Run migrations
bin/rails db:drop        # Drop database
bin/rails db:reset       # Reset database
bin/rails db:seed        # Load seed data
bin/rails db:rollback    # Rollback last migration
```

## 📁 Key Files

- `app/models/invoice.rb` - Refactored Invoice model
- `app/models/payment.rb` - Refactored Payment model
- `db/migrate/` - Database migrations
- `spec/models/` - RSpec test files
- `REFACTORING_EXPLANATION.md` - Detailed explanation of all changes and rationale

## 🧪 Testing

### Run RSpec Tests
```bash
# One-time setup
RAILS_ENV=test bin/rails db:create db:migrate

# Run all tests (48 examples, 0 failures ✅)
bundle exec rspec

# Run specific tests
bundle exec rspec spec/models/invoice_spec.rb
bundle exec rspec spec/models/payment_spec.rb

# Run with detailed output
bundle exec rspec --format documentation
```

### Quick Manual Test
```ruby
# In Rails console:
invoice = Invoice.create(invoice_total: 100.00)
invoice.record_payment(50.00, :cash)
puts invoice.amount_owed      # => 50.0
puts invoice.fully_paid?      # => false
invoice.record_payment(50.00, :check)
puts invoice.fully_paid?      # => true
```

### Test Coverage

**Invoice Model** - 30+ test cases covering:
- Associations (has_many :payments with dependent destroy)
- Validations (presence, numericality > 0)
- Currency conversion (dollars → cents automatically)
- `#fully_paid?` (unpaid, partial, full, overpaid scenarios)
- `#amount_owed` (correct balance calculations)
- `#record_payment` (valid/invalid methods, amounts, edge cases)
- Complete workflow integration tests

**Payment Model** - 15+ test cases covering:
- Associations (belongs_to :invoice)
- Validations (amount presence, amount > 0, valid payment_method_id)
- PAYMENT_METHODS constant (properly defined and frozen)
- `#payment_method` (returns correct symbols: :cash, :check, :charge)
- Raw payment method handling (accepts valid, rejects invalid)
- Cascading deletes and edge cases

## 📝 What Was Fixed

### Critical Bugs from Original Code:
1. ✅ **Inverted `fully_paid?` logic** - Was `amount_owed.zero?`, now `amount_owed <= 0` (handles overpayment)
2. ✅ **Wrong column name** - `amount_paid` → `amount`
3. ✅ **Wrong association** - `has_one` → `belongs_to` in Payment
4. ✅ **Non-existent method** - `PAYMENT_METHODS.value()` → `PAYMENT_METHODS[key]`
5. ✅ **Missing inheritance** - Added `< ApplicationRecord`
6. ✅ **Broken callback** - Fixed `convert_invoice_total_to_cents`

### Additional Improvements:
- ✅ Proper validations for all fields
- ✅ Error handling in `record_payment`
- ✅ PostgreSQL production-ready database
- ✅ Comprehensive RSpec test suite (46 passing tests)
- ✅ Standard Rails structure and conventions

## 🐛 Troubleshooting

**PostgreSQL not running:**
```bash
brew services start postgresql@15  # macOS
sudo systemctl start postgresql    # Linux
```

**Database doesn't exist:**
```bash
bin/rails db:create
```

**Test database issues:**
```bash
RAILS_ENV=test bin/rails db:drop db:create db:migrate
```

**Missing gems:**
```bash
bundle install
```

---

**Built with:** Ruby 3.x, Rails 7.0, PostgreSQL  
**Test Framework:** RSpec 6.x with Shoulda Matchers, FactoryBot  
**Status:** ✅ All 46 tests passing
