class CreateSodexoNotification < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_sodexo_notifications do |t|
      t.integer :payment_id
      t.integer :order_id
      t.timestamps
    end
  end
end
