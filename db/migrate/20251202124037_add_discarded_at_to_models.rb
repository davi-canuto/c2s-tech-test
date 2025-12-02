class AddDiscardedAtToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :discarded_at, :datetime
    add_index :customers, :discarded_at

    add_column :parser_records, :discarded_at, :datetime
    add_index :parser_records, :discarded_at

    add_column :medias, :discarded_at, :datetime
    add_index :medias, :discarded_at
  end
end
