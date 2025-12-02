class CreateParserRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :parser_records do |t|
      t.string :filename, null: false
      t.string :sender
      t.string :parser_used
      t.integer :status, null: false, default: 0
      t.jsonb :extracted_data, default: {}
      t.text :error_message
      t.references :customer, null: true, foreign_key: true

      t.timestamps
    end

    add_index :parser_records, :status
    add_index :parser_records, :created_at
    add_index :parser_records, :sender
  end
end
