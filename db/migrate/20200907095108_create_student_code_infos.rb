class CreateStudentCodeInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :student_code_infos do |t|
      t.string :student_id
      t.string :filename
      t.text :code

      t.timestamps
    end
  end
end
