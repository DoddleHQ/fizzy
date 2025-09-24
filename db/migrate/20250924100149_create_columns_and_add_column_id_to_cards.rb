class CreateColumnsAndAddColumnIdToCards < ActiveRecord::Migration[8.1]
  def change
    create_table :columns do |t|
      t.string :name,  null: false
      t.string :color, null: false
      t.references :collection, null: false, foreign_key: true
      t.timestamps
    end

    add_reference :cards, :column, foreign_key: true, index: true
  end
end
