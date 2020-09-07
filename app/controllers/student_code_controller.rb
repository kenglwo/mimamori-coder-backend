class StudentCodeController < ApplicationController
  def save
    result = ""
    code_data = params[:student_code]
    filename = code_data['studentId']
    code = code_data['code']
  end
end
