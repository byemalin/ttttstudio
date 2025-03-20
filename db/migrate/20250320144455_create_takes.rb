class CreateTakes < ActiveRecord::Migration[7.1]
  def change
    create_table :takes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :body, null: false, limit: 280
      t.timestamps
    end
  end
end
