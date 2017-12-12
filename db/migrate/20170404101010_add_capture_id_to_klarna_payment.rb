class AddCaptureIdToKlarnaPayment < ActiveRecord::Migration[5.0]
  def change
    add_column :spree_klarna_credit_payments, :capture_id, :string
  end
end
