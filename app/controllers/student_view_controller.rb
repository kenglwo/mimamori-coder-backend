class StudentViewController < ApplicationController
  def index
    student_id = params['student_id']
    commit_total_num = `git -C ~/git/#{student_id} log --oneline | wc -l`.strip()

    render json: {
      commitTotalNum: commit_total_num,
      currentCommitIndex: commit_total_num,
      files: [{
        fileName: "",
        commitIndex: 0,
        updatedTime: "2020-05-13 17:52",
        codeStatus: "ok",
        warningNum: 0,
        errorNum: 0
      }]
    }
  end

  def file_list
    student_id = params['student_id']
    json = {}
    json["fileNameList"] = []
    file_name_list = `git -C ~/git/#{student_id} ls-files`.split("\n")

    file_name_list.each do |file_name|
      json["fileNameList"].push(file_name)
      
    end

    render json: json

  end

end
