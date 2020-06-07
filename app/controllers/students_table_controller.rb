require 'open3'

class StudentsTableController < ApplicationController

  ALL_STUDENT_ID = "ls -1 ~/git"

  def index
    all_student_table_items = []

    all_student_id = `#{ALL_STUDENT_ID}`.split("\n")
    all_student_num = all_student_id.length

    all_student_id.each_with_index do |student_id, i|
      json = {}
      json["studentID"] = student_id
  

      json["workingFiles"]= []
      working_file_names = []


      cmd = "git -C ~/git/#{student_id}  log -1 --name-only | sed -n 1,6\!p"

      out, err, status = Open3.capture3(cmd)
      if not err.include?("fatal")
        working_file_names = out.split("\n")
      else
        working_file_names = ["unkown"]
      end


      for file_name in working_file_names do
        json_file = {}
        json_file["fileName"] = file_name

        cmd = "git -C ~/git/#{student_id} log --oneline | wc -l"
        out, err, status = Open3.capture3(cmd)
        if not err.include?("fatal")
          json_file["commitIndex"] = out.strip()
        else
          json_file["commitIndex"] = "unkown"
        end

        cmd = "git -C ~/git/#{student_id} log --oneline --pretty=format:'%cd' --date=format:'%Y/%m/%d %H:%M:%S' | head -1"
        out, err, status = Open3.capture3(cmd)
        if not err.include?("fatal")
          json_file["updatedTime"] = out.strip()
        else
          json_file["updatedTime"] = 'unkown'
        end
        
        # # TODO: check code status with linter
        # # code = `git -C ~/git/#{student_id} show HEAD:#{file_name}`.strip()
        # # json_file["codeStatus"] = "unknown"
        # json_file["warningNum"] = 0
        # json_file["errorNum"] = 0

        json["workingFiles"].push(json_file)
      end


      all_student_table_items.push(json)
    end

    render json: all_student_table_items
  end

  def test
    render plain: "API connected!"
  end
end
