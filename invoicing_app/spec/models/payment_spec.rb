require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { should belong_to(:invoice) }
  end

  describe 'validations' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }
    
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    
    it 'validates payment_method_id inclusion' do
      payment = invoice.payments.build(amount: 10000, payment_method_id: 99)
      expect(payment).not_to be_valid
      expect(payment.errors[:payment_method_id]).to include('must be valid')
    end
  end

  describe 'PAYMENT_METHODS constant' do
    it 'defines all payment methods' do
      expect(Payment::PAYMENT_METHODS).to eq({ cash: 1, check: 2, charge: 3 })
    end

    it 'is frozen' do
      expect(Payment::PAYMENT_METHODS).to be_frozen
    end
  end

  describe '#payment_method' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }

    it 'returns :cash for payment_method_id 1' do
      payment = invoice.payments.create(amount: 5000, payment_method_id: 1)
      expect(payment.payment_method).to eq(:cash)
    end

    it 'returns :check for payment_method_id 2' do
      payment = invoice.payments.create(amount: 5000, payment_method_id: 2)
      expect(payment.payment_method).to eq(:check)
    end

    it 'returns :charge for payment_method_id 3' do
      payment = invoice.payments.create(amount: 5000, payment_method_id: 3)
      expect(payment.payment_method).to eq(:charge)
    end
  end

  describe 'raw_payment_method handling' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }

    context 'with valid payment methods' do
      it 'accepts :cash symbol' do
        payment = invoice.payments.create(amount: 5000, raw_payment_method: :cash)
        expect(payment).to be_valid
        expect(payment.payment_method_id).to eq(1)
      end

      it 'accepts :check symbol' do
        payment = invoice.payments.create(amount: 5000, raw_payment_method: :check)
        expect(payment).to be_valid
        expect(payment.payment_method_id).to eq(2)
      end

      it 'accepts :charge symbol' do
        payment = invoice.payments.create(amount: 5000, raw_payment_method: :charge)
        expect(payment).to be_valid
        expect(payment.payment_method_id).to eq(3)
      end
    end

    context 'with invalid payment method' do
      it 'fails validation for :bitcoin' do
        payment = invoice.payments.build(amount: 5000, raw_payment_method: :bitcoin)
        expect(payment).not_to be_valid
        expect(payment.errors[:raw_payment_method]).to include('must be cash, check, or charge')
      end

      it 'fails validation for :credit_card' do
        payment = invoice.payments.build(amount: 5000, raw_payment_method: :credit_card)
        expect(payment).not_to be_valid
      end

      it 'fails validation for invalid string' do
        payment = invoice.payments.build(amount: 5000, raw_payment_method: 'paypal')
        expect(payment).not_to be_valid
      end
    end
  end

  describe 'amount storage' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }

    it 'stores amounts in cents (integer)' do
      payment = invoice.payments.create(amount: 10050, payment_method_id: 1)
      expect(payment.amount).to eq(10050)
      expect(payment.amount).to be_a(Integer)
    end

    it 'handles large amounts' do
      payment = invoice.payments.create(amount: 1_000_000, payment_method_id: 1)
      expect(payment.amount).to eq(1_000_000)
    end
  end

  describe 'cascading deletes' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }

    it 'is deleted when invoice is deleted' do
      payment = invoice.payments.create(amount: 10000, raw_payment_method: :cash)
      payment_id = payment.id
      
      invoice.destroy
      
      expect(Payment.find_by(id: payment_id)).to be_nil
    end
  end

  describe 'edge cases' do
    let(:invoice) { Invoice.create(invoice_total: 200.00) }

    it 'handles multiple payments on same invoice' do
      payment1 = invoice.payments.create(amount: 5000, raw_payment_method: :cash)
      payment2 = invoice.payments.create(amount: 3000, raw_payment_method: :check)
      payment3 = invoice.payments.create(amount: 2000, raw_payment_method: :charge)
      
      expect(invoice.payments.count).to eq(3)
      expect(invoice.payments.pluck(:payment_method_id).sort).to eq([1, 2, 3])
    end

    it 'validates amount is greater than zero' do
      payment = invoice.payments.build(amount: 0, raw_payment_method: :cash)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to be_present
    end

    it 'requires a payment_method_id' do
      payment = invoice.payments.build(amount: 5000)
      expect(payment).not_to be_valid
      expect(payment.errors[:payment_method_id]).to be_present
    end
  end
end