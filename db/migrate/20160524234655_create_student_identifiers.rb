class CreateStudentIdentifiers < ActiveRecord::Migration
  def change
    create_table :student_identifier_types do |t|
      t.belongs_to :organization, index: true
      t.string :name, null: false
      t.string :description, null: false
      t.integer :content_type, null: false
      t.datetime :deleted_at
    end

    create_table :student_identifiers do |t|
      t.belongs_to :organization, index: true
      t.belongs_to :user,         index: true
      t.belongs_to :student_identifier_type
      t.string :value, null: false
    end

    add_column :assignments, :student_identifier_type_id, :integer
    add_column :group_assignments, :student_identifier_type_id, :integer
  end
end
