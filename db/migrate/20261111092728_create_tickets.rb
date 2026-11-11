class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :assignee, foreign_key: { to_table: :users }
      t.references :category, foreign_key: true
      t.datetime :resolved_at

      t.timestamps
    end
    add_index :tickets, :status
  end
end