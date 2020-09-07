class LoginController < ApplicationController
  def login_student
    msg = ""

    auth_info = params[:login]
    student_id = auth_info["studentId"]
    class_code = auth_info["classCode"]
    class_password = auth_info["classPassword"]

    class_info = ClassInfo.find_by(class_code: class_code)

    if class_info.nil?
      msg = "Invalid Class Code"
    else
      logger.debug class_info.class_password
      logger.debug class_password
      msg = class_info['class_password'] == class_password ? "Success" : "Invalid Class Password"
    end

    render plain: msg
  end
end
