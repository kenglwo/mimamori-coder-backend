# frozen_string_literal: true

Rails.application.routes.draw do
  post 'api/login_student', to: 'login#login_student'
  post 'api/save_code', to: 'student_code#save'

  get 'api/students_table_items/:class_code', to: 'students_table#index'

  get 'api/student_view', to: 'student_view#index'
  get 'api/student_view/file_list', to: 'student_view#file_list'
  get 'api/student_view/commit_log', to: 'student_view#commit_log'
  get 'api/student_view/code', to: 'student_view#code'
  get 'api/student_view/code_string', to: 'student_view#code_string'
  get 'api/student_view/student_id_list', to: 'student_view#student_id_list'

  post 'api/auth_supervisor', to: 'auth_supervisor#auth'

  post 'api/comment_save', to: 'manage_comment#save'
  get 'api/comment_fetch', to: 'manage_comment#fetch'

  get 'api/class_list', to: 'class_info#list'

end
