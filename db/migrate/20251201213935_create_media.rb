class CreateMedia < ActiveRecord::Migration[8.0]
  def change
    create_table :medias do |t|
      t.string :filename
      t.bigint :file_size
      t.string :content_type
      t.string :checksum
      t.string :sender
      t.string :subject
      t.datetime :original_date

      t.timestamps
    end
  end
end
