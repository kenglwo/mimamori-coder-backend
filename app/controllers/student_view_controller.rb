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
          , saved_at
          , ROW_NUMBER() over (partition by student_id order by saved_at asc) as commits
          , ROW_NUMBER() over (partition by student_id order by saved_at desc) as num 
        from student_code_infos 
        order by student_id, commits desc
      ) as tmp 
      where student_id = :student_id and num = 1;
    EOF
    res = StudentCodeInfo.find_by_sql([query, { student_id: student_id }])[0]
    commits = res['commits']

    api_result = { commitTotalNum: commits, currentCommitIndex: commits }

    render json: api_result
  end

  def file_list
    student_id = params['student_id']
    json = {}
    json['fileNameList'] = []
    # file_name_obj = StudentCodeInfo.where(student_id: student_id).select('filename').distinct.order('saved_at asc')
    # TODO: order files
    file_name_obj = StudentCodeInfo.where(student_id: student_id).select('filename').distinct

    if file_name_obj.exists?
      file_name_obj.each do |obj|
        file_name = obj.filename.encode('UTF-8')
        json['fileNameList'].push(file_name)

        next unless file_name.downcase.end_with?('png', 'jpeg', 'jpg', 'gif')

        image_dir_path = "#{Rails.root}/public/images/#{student_id}"
        Dir.mkdir(image_dir_path) unless Dir.exist?(image_dir_path)
        file_name_base = File.basename(file_name)
        unless File.exist?("#{image_dir_path}/#{file_name_base}")
          `git -C ~/git/#{student_id} show "master:#{file_name}" > #{image_dir_path}/#{file_name_base}`
        end
      end
    end

    render json: json
  end

  def commit_log
    student_id = params['student_id']
    json = []
    # commit_time_array = `git -C ~/git/#{student_id} log --oneline --pretty=format:'%cd' --date=format:'%Y/%m/%d %H:%M:%S'`.split("\n")

    commit_log_array = StudentCodeInfo.where(student_id: student_id).select(:saved_at, :filename).order('saved_at desc')

    if commit_log_array.exists?
      commit_log_array.each do |obj|
        commit_log = {
          commitTime: '',
          commitFile: []
        }
        commit_log['commitTime'] = obj['saved_at'].nil? ? 'null' : obj['saved_at'].strftime('%Y/%m/%d %H:%M:%S')
        file_info = { fileName: '', fileStatus: '' }
        file_info['fileName'] = obj['filename']
        commit_log[:commitFile].push(file_info)
        json.push(commit_log)
      end
    end

    # json = {
    #   commitTime: "string"
    #   commitFile: [
    #     filename: "string",
    #     fileStatus: "M"
    #   ]
    # }

    # commit_last_index = commit_time_array.length - 1
    #
    # commit_log_info = `git -C ~/git/#{student_id} log --name-status`
    # commit_log_info_lines = `git -C ~/git/#{student_id} log --name-status | wc -l`.strip.to_i
    #
    # commit_index = -1
    # commit_log = {}
    #
    # commit_log_info.each_line.with_index do |line, index|
    #   linenum = index + 1
    #
    #   if line.index('commit') == 0
    #     if commit_log != {}
    #       json.push(commit_log)
    #       commit_log = {}
    #     end
    #     commit_index += 1
    #     commit_log['commitTime'] = commit_time_array[commit_index]
    #     commit_log['commitFile'] = []
    #   end
    #
    #   unless (line.index("A\t") == 0) || (line.index("M\t") == 0) || (line.index("D\t") == 0)
    #     next
    #   end
    #
    #   file_info = line.split("\t")
    #   commit_file = {
    #     fileName: file_info[1].strip,
    #     fileStatus: file_info[0]
    #   }
    #
    #   commit_log['commitFile'].push(commit_file)
    #
    #   if commit_index == commit_last_index && linenum == commit_log_info_lines
    #     json.push(commit_log)
    #     commit_log = {}
    #   end
    # end

    render json: json
  end

  def code
    student_id = params['student_id']
    current_commit_index = params['current_commit_index']

    api_result = []

    commit_total_num = StudentCodeInfo.where(student_id: student_id).count
    offset = current_commit_index.to_i - 1
    offset = 0 if offset < 0

    query = <<-EOF
      select 
        saved_at
        , filename
        , code
        , lag(code) over(partition by filename) as prev_code
      from student_code_infos 
      where student_id = :student_id
      order by saved_at asc
      offset :offset
      limit 1
    EOF
    code_array = StudentCodeInfo.find_by_sql([query, { student_id: student_id, offset: offset }])

    unless code_array.empty?
      code_array.each do |code_info|
        json = {}
        json['fileName'] = code_info['fileName']
        json['commitTime'] = code_info['saved_at'].nil? ? 'null' : code_info['saved_at'].strftime('%Y/%m/%d %H:%M:%S')
        json['codeString'] = code_info['code']

        current_code = code_info['code']
        previous_code = code_info['prev_code']
        command = "diff <(echo #{current_code}) <(echo #{previous_code})"
        code_diff = `command`

        json['codeDiff'] = code_diff
        json['codeStatus'] = 'unknown'
        api_result.push(json)
      end
    end

    render json: api_result
  end

  def code_string
    student_id = params['student_id']
    current_commit_index = params['current_commit_index']

    commit_total_num = StudentCodeInfo.where(student_id: student_id).count
    offset = current_commit_index.to_i - 1
    offset = 0 if offset < 0
    # head_hat_num = commit_total_num.to_i - current_commit_index.to_i

    # head = 'HEAD'
    # head_hat_num.times do
    #   head += '^'
    # end

    # filename_array = `git -C ~/git/#{student_id} show --name-only #{head} | sed -n 1,6\!p`.split("\n")
    code_string_array = []

    query = <<-EOF
      select 
        filename
        , code
        , created_at
      from student_code_infos 
      where student_id = :student_id
      order by saved_at asc
      offset :offset
      limit 1
    EOF
    file_array = StudentCodeInfo.find_by_sql([query, { student_id: student_id, offset: offset }])
    file_array.each do |file|
      next unless file['filename'].end_with?('html', 'css', 'js')

      parsed_code_string = ''

      if file['filename'].end_with?('html')
        parsed_code_string = Nokogiri::HTML.parse(file['code'])
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
          filename: file['filename'],
          createdAt: file['created_at'],
          codeString: parsed_code_string.to_html
        }
        code_string_array.push(json)
      else
        json = {
          filename: file['filename'],
          createdAt: file['created_at'],
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
