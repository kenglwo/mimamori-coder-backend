# frozen_string_literal: true

require 'open3'

class StudentsTableController < ApplicationController
  ALL_STUDENT_ID = 'ls -1 ~/git'

  def index
    all_student_table_items = []

    query = <<-EOF
        select 
          student_id
          , filename
          , code
          , created_at
          , commits
        from (
          select
            student_id
            , filename
            , code
            , created_at 
            , ROW_NUMBER() over (partition by student_id order by created_at asc) as commits
            , ROW_NUMBER() over (partition by student_id order by created_at desc) as num 
          from student_code_infos 
          order by student_id, commits desc
        ) as tmp 
        where num = 1;
    EOF

    student_infos = StudentCodeInfo.find_by_sql(query)
    student_infos.each do |student_info|
      json = {}
      json['studentID'] = student_info['student_id'].nil? ? "null" : student_info['student_id']

      json['workingFiles'] = []
      json_file = {}
      json_file['fileName'] = student_info['filename']
      json_file['commitIndex'] = student_info['commits']
      json_file['updatedTime'] = student_info['created_at'].strftime('%Y/%m/%d %H:%M:%S')
      json['workingFiles'].push(json_file)

      all_student_table_items.push(json)
    end

    # # TODO: check code status with linter
    # code = `git -C ~/git/#{student_id} show HEAD:#{file_name}`.strip
    # json_file['codeStatus'] = 'unknown'
    # json_file['warningNum'] = 0
    # json_file['errorNum'] = 0

    render json: all_student_table_items
  end
end
