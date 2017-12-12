require "spec_helper"

describe Spree::Klarna::SessionsController do
  describe "#create" do
    let(:order) { create(:order_with_line_items, state: "payment") }
    let!(:payment_method) { Spree::Gateway::KlarnaCredit.create(name: 'Klarna Credit') }

    before do
      payment_method.preferred_api_key = ENV['KLARNA_API_KEY'] || "test"
      payment_method.preferred_api_secret = ENV['KLARNA_API_SECRET'] || "test"
      payment_method.preferred_country = "us"
      payment_method.save!
      allow(controller).to receive(:current_order).and_return(order)
    end

    context "with expired Klarna session", :vcr do
      it "updates the order" do
        post :create, params: {klarna_payment_method_id: payment_method.id}
        expect(order.reload.klarna_client_token).to be_present
        expect(order.klarna_session_id).to be_present
        expect(order.klarna_session_expired?).to eq(false)
      end

      it "outputs the client token" do
        post :create, params: {klarna_payment_method_id: payment_method.id}
        expect(JSON.parse(response.body)['token']).to eq(order.reload.klarna_client_token)
      end
    end

    context "with an empty session_id", :vcr do
      let(:order) { create(:order_with_line_items,
                           state: "payment",
                           klarna_session_id: "",
                           klarna_client_token: "",
                           klarna_session_expires_at: 15.minutes.from_now) }

      it "return 422" do
        post :create, params: {klarna_payment_method_id: payment_method.id}
        expect(response.status).to eq(422)
      end
    end
  end
end
