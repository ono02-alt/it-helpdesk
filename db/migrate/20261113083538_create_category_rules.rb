class CreateCategoryRules < ActiveRecord::Migration[8.1]
  def change
    create_table :category_rules do |t|
      t.references :category, null: false, foreign_key: true
      t.string :keyword, null: false

      t.timestamps
    end
    add_index :category_rules, [ :category_id, :keyword ], unique: true
  end
end
