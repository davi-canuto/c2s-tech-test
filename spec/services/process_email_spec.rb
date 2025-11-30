require "rails_helper"

RSpec.describe ProcessEmail do
  let(:email_file) { File.open(Rails.root.join("spec/emails/email1.eml")) }
  let(:service) { described_class.new(email_file) }

  describe "#call" do
    context "with a valid email from Supplier A" do
      it "creates a customer" do
        expect {
          service.call
        }.to change(Customer, :count).by(1)
      end

      it "creates a success parser record" do
        expect {
          service.call
        }.to change(ParserRecord, :count).by(1)

        expect(service.parser_record.status).to eq("success")
      end

      it "extracts correct data" do
        customer = service.call

        expect(customer.name).to eq("João da Silva")
        expect(customer.email).to eq("joao.silva@example.com")
        expect(customer.phone).to eq("11912345678")
        expect(customer.product_code).to eq("ABC123")
      end

      it "returns the customer" do
        customer = service.call
        expect(customer).to be_a(Customer)
        expect(customer).to be_persisted
      end

      it "marks service as successful" do
        service.call
        expect(service.success?).to be true
      end
    end

    context "with a valid email from Partner B" do
      let(:email_file) { File.open(Rails.root.join("spec/emails/email4.eml")) }

      it "creates a customer with Partner B data" do
        customer = service.call

        expect(customer.name).to eq("Ana Costa")
        expect(customer.email).to eq("ana.costa@example.com")
      end

      it "uses PartnerBParser" do
        service.call
        expect(service.parser_record.parser_used).to eq("Parsers::PartnerBParser")
      end
    end

    context "with an incomplete email (no contact info)" do
      let(:email_file) { File.open(Rails.root.join("spec/emails/email7.eml")) }

      it "does not create a customer" do
        expect {
          service.call
        }.not_to change(Customer, :count)
      end

      it "creates a failed parser record" do
        expect {
          service.call
        }.to change(ParserRecord, :count).by(1)

        expect(service.parser_record.status).to eq("failed")
      end

      it "records the error message" do
        service.call
        expect(service.parser_record.error_message).to include("contact information")
      end

      it "marks service as not successful" do
        service.call
        expect(service.success?).to be false
      end
    end

    context "with an email from unknown sender" do
      let(:email_content) do
        <<~EMAIL
          From: unknown@example.com
          To: test@test.com
          Subject: Test

          Some content here
        EMAIL
      end
      let(:email_file) { StringIO.new(email_content) }

      it "creates a failed parser record" do
        expect {
          service.call
        }.to change(ParserRecord, :count).by(1)

        expect(service.parser_record.status).to eq("failed")
        expect(service.parser_record.error_message).to include("No parser found")
      end

      it "does not create a customer" do
        expect {
          service.call
        }.not_to change(Customer, :count)
      end
    end
  end
end
