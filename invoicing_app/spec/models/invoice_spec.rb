require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe 'associations' do
    it { should have_many(:payments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:invoice_total) }
    
    it 'validates invoice_total is greater than 0' do
      invoice = Invoice.new(invoice_total: 0)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:invoice_total]).to include('must be greater than 0')
      
      invoice.invoice_total = -10
      expect(invoice).not_to be_valid
      
      invoice.invoice_total = 100
      expect(invoice).to be_valid
    end
  end

  describe 'currency conversion' do
    it 'converts dollar amounts to cents on creation' do
      invoice = Invoice.create(invoice_total: 200.00)
      expect(invoice.invoice_total).to eq(20000) # 200 dollars = 20000 cents
    end

    it 'handles integer dollar amounts' do
      invoice = Invoice.create(invoice_total: 100)
      expect(invoice.invoice_total).to eq(10000)
    end
  end

  describe '#fully_paid?' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }

    context 'when no payments have been made' do
      it 'returns false' do
        expect(invoice.fully_paid?).to be false
      end
    end

    context 'when partially paid' do
      before do
        invoice.record_payment(100.00, :cash)
      end

      it 'returns false' do
        expect(invoice.fully_paid?).to be false
      end
    end

    context 'when fully paid' do
      before do
        invoice.record_payment(200.00, :cash)
      end

      it 'returns true' do
        expect(invoice.fully_paid?).to be true
      end
    end

    context 'when overpaid' do
      before do
        invoice.record_payment(200.00, :cash)
      end

      it 'returns true' do
        expect(invoice.fully_paid?).to be true
      end
    end

    context 'when attempting to overpay' do
      it 'prevents overpayment' do
        result = invoice.record_payment(250.00, :cash)
        expect(result).to be false
        puts invoice.errors.full_messages
        expect(invoice.errors[:base]).to include("Payment amount ($250.0) exceeds amount owed ($200.0)")
      end

      it 'does not create a payment record' do
        expect {
          invoice.record_payment(250.00, :cash)
        }.not_to change { invoice.payments.count }
      end
    end
  end

  describe '#amount_owed' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }

    context 'with no payments' do
      it 'returns the full invoice total in dollars' do
        expect(invoice.amount_owed).to eq(200.00)
      end
    end

    context 'with partial payment' do
      before do
        invoice.record_payment(75.50, :cash)
      end

      it 'returns the remaining balance in dollars' do
        expect(invoice.amount_owed).to eq(124.50)
      end
    end

    context 'with multiple payments' do
      before do
        invoice.record_payment(50.00, :cash)
        invoice.record_payment(100.00, :check)
        invoice.record_payment(25.00, :charge)
      end

      it 'returns the remaining balance in dollars' do
        expect(invoice.amount_owed).to eq(25.00)
      end
    end

    context 'when fully paid' do
      before do
        invoice.record_payment(200.00, :cash)
      end

      it 'returns zero' do
        expect(invoice.amount_owed).to eq(0.0)
      end
    end
  end

  describe '#record_payment' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }

    context 'with valid payment' do
      it 'creates a payment record' do
        expect {
          invoice.record_payment(100.00, :cash)
        }.to change { invoice.payments.count }.by(1)
      end

      it 'returns the payment object' do
        payment = invoice.record_payment(100.00, :cash)
        expect(payment).to be_a(Payment)
        expect(payment.persisted?).to be true
      end

      it 'stores amount in cents' do
        payment = invoice.record_payment(100.50, :cash)
        expect(payment.amount).to eq(10050)
      end
    end

    context 'with valid payment methods' do
      it 'accepts cash payments' do
        payment = invoice.record_payment(50.00, :cash)
        expect(payment.payment_method).to eq(:cash)
      end

      it 'accepts check payments' do
        payment = invoice.record_payment(50.00, :check)
        expect(payment.payment_method).to eq(:check)
      end

      it 'accepts charge payments' do
        payment = invoice.record_payment(50.00, :charge)
        expect(payment.payment_method).to eq(:charge)
      end
    end

    context 'with invalid payment method' do
      it 'returns false' do
        payment = invoice.record_payment(50.00, :bitcoin)
        expect(payment).to be false
      end

      it 'does not create a payment record' do
        expect {
          invoice.record_payment(50.00, :bitcoin)
        }.not_to change { invoice.payments.count }
      end
    end

    context 'with negative amount' do
      it 'returns false' do
        payment = invoice.record_payment(-50.00, :cash)
        expect(payment).to be false
      end

      it 'does not create a payment record' do
        expect {
          invoice.record_payment(-50.00, :cash)
        }.not_to change { invoice.payments.count }
      end
    end

    context 'with zero amount' do
      it 'returns false' do
        payment = invoice.record_payment(0, :cash)
        expect(payment).to be false
      end
    end
  end

  describe 'complete payment workflow' do
    it 'handles multiple payments correctly' do
      invoice = Invoice.create(invoice_total: 500.00)
      
      # First payment
      payment1 = invoice.record_payment(200.00, :cash)
      expect(payment1).to be_persisted
      expect(invoice.amount_owed).to eq(300.00)
      expect(invoice.fully_paid?).to be false
      
      # Second payment
      payment2 = invoice.record_payment(150.00, :check)
      expect(payment2).to be_persisted
      expect(invoice.amount_owed).to eq(150.00)
      expect(invoice.fully_paid?).to be false
      
      # Final payment
      payment3 = invoice.record_payment(150.00, :charge)
      expect(payment3).to be_persisted
      invoice.reload
      expect(invoice.amount_owed).to eq(0.0)
      expect(invoice.fully_paid?).to be true
      
      # Verify all payments
      expect(invoice.payments.count).to eq(3)
    end
  end
end