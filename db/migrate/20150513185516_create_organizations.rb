class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.integer :github_id,        null: false
      t.string  :title,            null: false
      t.string  :email_domain,      null: true

      t.timestamps null: false
    end

    add_index :organizations, :github_id,        unique: true
    add_index :organizations, :title,            unique: true

    create_table :organizations_users, id: false do |t|
      t.belongs_to :user,         index: true
      t.belongs_to :organization, index: true
    end
  end
end
