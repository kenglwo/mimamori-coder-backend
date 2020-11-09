class CreateCommentInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :comment_infos do |t|
      t.string :student_id
      t.text :comment
      t.integer :commit_index

      t.timestamps
    end
  end
end
