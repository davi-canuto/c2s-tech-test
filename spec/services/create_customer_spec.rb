require "rails_helper"

RSpec.describe CreateCustomerService do
  describe "#call" do
    context "with valid data" do
      let(:data) do
        {
          name: "João Silva",
          email: "joao@example.com",
          phone: "11999999999",
          product_code: "PROD-123",
          subject: "Test Subject"
        }
      end
      let(:service) { described_class.new(data) }

      it "creates a customer" do
        expect {
          service.call
        }.to change(Customer, :count).by(1)
      end

      it "sets customer attributes correctly" do
        customer = service.call

        expect(customer.name).to eq("João Silva")
        expect(customer.email).to eq("joao@example.com")
        expect(customer.phone).to eq("11999999999")
        expect(customer.product_code).to eq("PROD-123")
        expect(customer.email_subject).to eq("Test Subject")
      end

      it "returns the customer" do
        customer = service.call
        expect(customer).to be_a(Customer)
        expect(customer).to be_persisted
      end

      it "marks as successful" do
        service.call
        expect(service.success?).to be true
      end
    end

    context "with invalid data (no contact info)" do
      let(:data) do
        {
          name: "João Silva",
          email: nil,
          phone: nil,
          product_code: "PROD-123",
          subject: "Test"
        }
      end
      let(:service) { described_class.new(data) }

      it "does not create a customer" do
        expect {
          service.call
        }.not_to change(Customer, :count)
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end

      it "marks as not successful" do
        service.call
        expect(service.success?).to be false
      end

      it "records errors" do
        service.call
        expect(service.errors).not_to be_empty
      end
    end

    context "with missing name" do
      let(:data) do
        {
          name: nil,
          email: "test@example.com",
          phone: "11999999999",
          product_code: "PROD-123",
          subject: "Test"
        }
      end
      let(:service) { described_class.new(data) }

      it "does not create a customer" do
        expect {
          service.call
        }.not_to change(Customer, :count)
      end

      it "records the validation error" do
        service.call
        expect(service.errors.first).to include("Name")
      end
    end
  end

  describe "#call!" do
    context "with valid data" do
      let(:data) { { name: "Test", email: "test@example.com" } }
      let(:service) { described_class.new(data) }

      it "creates and returns customer" do
        expect(service.call!).to be_a(Customer)
      end
    end

    context "with invalid data" do
      let(:data) { { name: nil, email: nil, phone: nil } }
      let(:service) { described_class.new(data) }

      it "raises ActiveRecord::RecordInvalid" do
        expect {
          service.call!
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
