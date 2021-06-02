require 'spec_helper'

RSpec.describe SodexoOrder, type: :lib do
  describe "#description" do
    let(:current_store) { FactoryBot.create(:store, name: 'xx xxx', default: true) }

    before do
      I18n.locale = :en
      allow(Spree::Store).to receive(:current).and_return(current_store)
    end

    subject { described_class.description }

    it "returns default description" do
      expect(subject).to eq("Order from #{current_store.name}")
    end
  end

  describe "#currency" do
    let(:order) { OrderWalkthrough.up_to(:payment) }

    before do
      order.currency = 'CLP'
    end

    subject { described_class.currency(order) }

    it "returns default CLP currency" do
      expect(subject).to eq('CLP')
    end
  end

  describe "#amount" do
    let(:order) { OrderWalkthrough.up_to(:payment) }

    subject { described_class.amount(order) }

    it "returns default order's total amount" do
      expect(subject).to eq(order.total.to_f)
    end
  end

  describe "#options" do
    let(:order) { OrderWalkthrough.up_to(:payment) }
    let(:order_url) { "http://localhost:5252/order_url/1234" }
    let(:notify_url) { "http://localhost:5252/order_url/notify/1234" }
    let(:continue_url) { "http://localhost:5252/order_url/checkout/continue" }
    let(:current_store) { FactoryBot.create(:store, name: 'xx xxx', default: true) }

    before do
      I18n.locale = :es
      allow(Sodexo::Configuration).to receive(:receiver_id).and_return("319376")
      allow(Spree::Store).to receive(:current).and_return(current_store)
    end

    subject { described_class.options(order, order_url, notify_url) }

    it "returns well structured options from real order" do
      expect(subject).to eq(
                             transaction_id: order.id,
                             custom: [
                                       {
                                         name: order.line_items.first.product.name,
                                         unit_price: order.line_items.first.price.to_f,
                                         quantity: 1
                                       }
                                     ],
                             body: 'Compra en xx xxx',
                             bank_id: nil,
                             return_url: "http://localhost:5252/order_url/1234",
                             cancel_url: "http://localhost:5252/order_url/1234",
                             picture_url: nil,
                             notify_url: "http://localhost:5252/order_url/notify/1234",
                             contract_url: nil,
                             notify_api_version: nil,
                             expires_date: subject[:expires_date],
                             send_email: nil,
                             payer_name: "John Doe",
                             payer_email: "spree@example.com",
                             send_reminders: nil,
                             responsible_user_email: nil,
                             fixed_payer_personal_identifier: nil,
                             integrator_fee: nil,
                             collect_account_uuid: nil,
                             confirm_timeout_date: nil,
                             mandatory_payment_method: nil
                         )

      expect(subject[:custom][0][:name]).to be_present
    end
  end
end
