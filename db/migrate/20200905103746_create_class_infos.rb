class CreateClassInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :class_infos do |t|
      t.string :class_code
      t.string :class_name
      t.string :class_password
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
