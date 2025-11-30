class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :product_code
      t.string :email_subject

      t.timestamps
    end

    add_index :customers, :email
    add_index :customers, :created_at
  end
end
