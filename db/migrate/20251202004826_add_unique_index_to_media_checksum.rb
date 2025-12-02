class AddUniqueIndexToMediaChecksum < ActiveRecord::Migration[8.0]
  def change
    add_index :medias, :checksum, unique: true
  end
end
