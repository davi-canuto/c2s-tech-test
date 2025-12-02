class AddMediaToParserRecords < ActiveRecord::Migration[8.0]
  def change
    add_reference :parser_records, :media, null: true, foreign_key: { to_table: :medias }
  end
end
