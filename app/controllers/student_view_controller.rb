# frozen_string_literal: true

require 'nkf'
require 'nokogiri'

class StudentViewController < ApplicationController
  def index
    student_id = params['student_id']
    api_result = { commitTotalNum: 0, currentCommitIndex: 0 }
    # cmd = "git -C ~/git/#{student_id} log --oneline | wc -l"
    # commit_total_num = `#{cmd}`.strip

    query = <<-EOF
      select 
        commits 
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
      where student_id = :student_id and num = 1;
    EOF
    res = StudentCodeInfo.find_by_sql([query, { student_id: student_id }])[0]
    commits = res['commits']

    api_result = { commitTotalNum: commits, currentCommitIndex: commits }

    render json: api_result
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
    json['fileNameList'] = []
    file_name_list = `git -C ~/git/#{student_id} ls-files`.split("\n")

    file_name_list.each do |file_name|
      file_name = file_name.encode('UTF-8')
      json['fileNameList'].push(file_name)

      next unless file_name.downcase.end_with?('png', 'jpeg', 'jpg', 'gif')

      image_dir_path = "#{Rails.root}/public/images/#{student_id}"
      Dir.mkdir(image_dir_path) unless Dir.exist?(image_dir_path)
      file_name_base = File.basename(file_name)
      unless File.exist?("#{image_dir_path}/#{file_name_base}")
        `git -C ~/git/#{student_id} show "master:#{file_name}" > #{image_dir_path}/#{file_name_base}`
  end
    end

    render json: json
  end

  def commit_log
    student_id = params['student_id']
    json = []
    commit_time_array = `git -C ~/git/#{student_id} log --oneline --pretty=format:'%cd' --date=format:'%Y/%m/%d %H:%M:%S'`.split("\n")

    commit_last_index = commit_time_array.length - 1

    commit_log_info = `git -C ~/git/#{student_id} log --name-status`
    commit_log_info_lines = `git -C ~/git/#{student_id} log --name-status | wc -l`.strip.to_i

    commit_index = -1
    commit_log = {}

    commit_log_info.each_line.with_index do |line, index|
      linenum = index + 1

      if line.index('commit') == 0
        if commit_log != {}
          json.push(commit_log)
          commit_log = {}
        end
        commit_index += 1
        commit_log['commitTime'] = commit_time_array[commit_index]
        commit_log['commitFile'] = []
      end

      unless (line.index("A\t") == 0) || (line.index("M\t") == 0) || (line.index("D\t") == 0)
        next
      end

      file_info = line.split("\t")
      commit_file = {
        fileName: file_info[1].strip,
        fileStatus: file_info[0]
      }

      commit_log['commitFile'].push(commit_file)

      if commit_index == commit_last_index && linenum == commit_log_info_lines
        json.push(commit_log)
        commit_log = {}
      end
    end

    render json: json
  end

  def code
    student_id = params['student_id']
    current_commit_index = params['current_commit_index']

    commit_total_num = `git -C ~/git/#{student_id} log --oneline | wc -l`.strip
    head_hat_num = commit_total_num.to_i - current_commit_index.to_i
    head = 'HEAD'
    head_hat_num.times do
      head += '^'
    end
    # TODO: set prevHead properly
    prevHead = "#{head}^"

    filename_array = `git -C ~/git/#{student_id} show --name-only #{head} | sed -n 1,6\!p`.split("\n")

    commit_time = `git -C ~/git/#{student_id} show #{head} --pretty=format:'%cd' --date=format:'%Y/%m/%d %H:%M:%S' | head -1`.strip

    code_string_array = []
    code_diff_array = []

    filename_array.each do |filename|
      next unless filename.end_with?('html', 'css', 'js')

      code_string = `git -C ~/git/#{student_id} show #{head}:#{filename}`.strip
      code_string_array.push(code_string)
      code_diff = `git -C ~/git/#{student_id} diff #{prevHead}:#{filename} #{head}:#{filename}`.strip
      code_diff_array.push(code_diff)
    end

    code_status_array = []
    code_string_array.each do |_code|
      # TODO: check the code with linter
      code_status_array.push('unknown')
    end

    json = []

    filename_array.each_with_index do |filename, i|
      next unless filename.end_with?('html', 'css', 'js')

      code_info = {
        fileName: filename,
        commitTime: commit_time,
        codeString: code_string_array[i],
        codeDiff: code_diff_array[i],
        codeStatus: code_status_array[i]
      }
      json.push(code_info)
    end

    render json: json
  end

  def code_string
    student_id = params['student_id']
    current_commit_index = params['current_commit_index']

    commit_total_num = `git -C ~/git/#{student_id} log --oneline | wc -l`.strip
    head_hat_num = commit_total_num.to_i - current_commit_index.to_i

    head = 'HEAD'
    head_hat_num.times do
      head += '^'
    end

    filename_array = `git -C ~/git/#{student_id} show --name-only #{head} | sed -n 1,6\!p`.split("\n")
    code_string_array = []
    filename_array.each do |filename|
      next unless filename.end_with?('html', 'css', 'js')

      code_string = `git -C ~/git/#{student_id} show "#{head}:#{filename}"`.strip
      parsed_code_string = ''

      if filename.end_with?('html')
        parsed_code_string = Nokogiri::HTML.parse(code_string)
        parsed_code_string.css('img').each do |e|
          image_filename = e[:src]
          unless image_filename.start_with?('http')
            image_path = "#{ENV['APP_URL']}/images/#{student_id}/#{image_filename}"
            e[:src] = image_path
          end
        end

        parsed_code_string.css('table').each do |e|
          next unless e[:background].present?

          image_filename = e[:background]
          unless image_filename.start_with?('http')
            image_path = "#{ENV['APP_URL']}/images/#{student_id}/#{image_filename}"
            e[:background] = image_path
          end
        end

        json = {
          codeString: parsed_code_string.to_html
        }
        code_string_array.push(json)
      else
        json = {
          codeString: code_string
        }
        code_string_array.push(json)
      end
    end

    render json: code_string_array
  end

  def student_id_list
    api_result = `ls -1 ~/git`.split("\n")

    render json: api_result
  end
end
