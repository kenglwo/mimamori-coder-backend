class StudentCodeController < ApplicationController
  def save
    api_result = ""

    code_data = params[:student_code]
    student_id = code_data['student_id']
    filename = code_data['filename']
    code = code_data['code']

    begin
      StudentCodeInfo.create(student_code_params)
      api_result = "Success"
    rescue => e
      logger.debug e
      api_result = e.message
    end

    render plain: api_result

  end

  private
  def student_code_params
    params.require(:student_code).permit(:student_id, :filename, :code)
  end
end
