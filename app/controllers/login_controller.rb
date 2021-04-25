class LoginController < ApplicationController
  def login_student
    msg = ""

    auth_info = params[:login]

    student_id = auth_info["student_id"]
    class_code = auth_info["class_code"]
    class_password = auth_info["class_password"]

    class_info = ClassInfo.find_by(class_code: class_code)

    if class_info.nil?
      msg = "Invalid Class Code"
    else
      msg = class_info['class_password'] == class_password ? "Success" : "Invalid Class Password"
    end

    render plain: msg
  end
end
