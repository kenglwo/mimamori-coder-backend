require 'json'

class StudentCodeController < ApplicationController
  def save
    api_result = ""

    # code_data_array = JSON.parse(params[:student_code])
    code_data_array = JSON.parse(request.body.read)
    logger.debug "==============================="
    logger.debug code_data_array

    code_data_array.each do |code_data|
      student_id = code_data['student_id']
      filename = code_data['filename']
      code = code_data['code']
      saved_at = code_data['saved_at']

      begin
        StudentCodeInfo.create(student_id: student_id, filename: filename, code: code, saved_at: saved_at)
        api_result = "Success"
      rescue => e
        logger.debug e
        api_result = e.message
      end
    end

    render plain: api_result

  end

  private
  def student_code_params
    params.require(:student_code).permit(:student_id, :filename, :code)
  end
end
