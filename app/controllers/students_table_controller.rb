class StudentsTableController < ApplicationController

  ALL_STUDENT_ID = "ls -1 ~/git"
  ALL_STUDENT_NAME = "find ~/git -maxdepth 2 -type d | sort | xargs basename | sed -e /git/d | awk 'NR%2==0'"

  def index
    all_student_table_items = []

    all_student_id = `#{ALL_STUDENT_ID}`.split("\n")
    all_student_name = `#{ALL_STUDENT_NAME}`.split("\n")
    all_student_num = all_student_id.length

    all_student_id.each_with_index do |student_id, i|
      json = {}
      json["studentID"] = student_id
      json["studentName"] = all_student_name[i]
  

      json["workingFiles"]= []
      working_file_names = `git -C ~/git/#{student_id}  log -1 --name-only | sed -n 1,6\!p`.split("\n")
      for file_name in working_file_names do
        json_file = {}
        json_file["fileName"] = file_name

      json_file["commitIndex"] = `git -C ~/git/#{student_id} log --oneline | wc -l`.strip()
      json_file["updatedTime"] = `git -C ~/git/#{student_id} log --oneline --pretty=format:'%cd' --date=format:'%Y/%m/%d %H:%M:%S' | head -1`.strip()

        # TODO: check code status with linter
        code = `git -C ~/git/#{student_id} show HEAD:#{file_name}`.strip()
        json_file["codeStatus"] = "unknown"

        json_file["warningNum"] = 0
        json_file["errorNum"] = 0
        json["workingFiles"].push(json_file)
      end

      all_student_table_items.push(json)
    end

    render json: all_student_table_items
  end
end
