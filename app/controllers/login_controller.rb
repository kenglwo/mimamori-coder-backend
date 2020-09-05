class LoginController < ApplicationController
  def login_student
    #TODO: fetch class info from DB
    class_info = {"pe2020" => "xxxx"}
    # login_status = {"success" => 0, "class_code_error": 1, "class_password_error": 2}
    msg = ""

    auth_info = params[:students_table]
    student_id = auth_info["studentId"]
    class_code = auth_info["classCode"]
    class_password = auth_info["classPassword"]

    if(class_info[class_code] == class_password)    
      msg = "Connection Establised!"
    else 
      msg = "Error"
    end

    render plain: msg
  end
end
