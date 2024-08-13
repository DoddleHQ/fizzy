class RenameOrganizationsToAccounts < ActiveRecord::Migration[8.0]
  def change
    rename_table :organizations, :accounts
    add_index :accounts, :name, unique: true

    rename_column :users, :organization_id, :account_id
    add_index :users, :account_id
  end
end
