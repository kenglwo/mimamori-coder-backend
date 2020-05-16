class StudentViewController < ApplicationController
  def index
    student_id = params['student_id']
    commit_total_num = `git -C ~/git/#{student_id} log --oneline | wc -l`.strip()

    render json: {
      commitTotalNum: commit_total_num,
      currentCommitIndex: commit_total_num
    }
    # render json: {
    #   commitTotalNum: commit_total_num,
    #   currentCommitIndex: commit_total_num,
    #   files: [{
    #     fileName: "",
    #     commitIndex: 0,
    #     updatedTime: "2020-05-13 17:52",
    #     codeStatus: "ok",
    #     warningNum: 0,
    #     errorNum: 0
    #   }]
    # }
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

  def commit_log
    student_id = params['student_id']
    json = []
    commit_time_array = `git -C ~/git/#{student_id} log --oneline --pretty=format:'%cd' --date=format:'%Y/%m/%d %H:%M:%S'`.split("\n")

    commit_last_index = commit_time_array.length - 1

    commit_log_info = `git -C ~/git/#{student_id} log --name-status`

    commit_index = -1
    commit_log = {}

    commit_log_info.each_line do |line|

      if line.index("commit") == 0
        if commit_log != {}
          json.push(commit_log)
          commit_log = {}
        end
        commit_index += 1
        commit_log["commitTime"] = commit_time_array[commit_index]
        commit_log["commitFile"] = []
      end
    
      if line.index("A\t") == 0 or line.index("M\t") == 0 or line.index("D\t") == 0
        file_info = line.split("\t")
        commit_file = {
          fileName: file_info[1].strip(),
          fileStatus: file_info[0]
        }
        commit_log["commitFile"].push(commit_file)

        if commit_index == commit_last_index
          json.push(commit_log)
          commit_log = {}
        end

        
      end
    end

    render json: json
  end

end
