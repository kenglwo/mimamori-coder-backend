# frozen_string_literal: true

Rails.application.routes.draw do
  get 'api/students_table_items', to: 'students_table#index'

  get 'api/student_view', to: 'student_view#index'
  get 'api/student_view/file_list', to: 'student_view#file_list'
  get 'api/student_view/commit_log', to: 'student_view#commit_log'
  get 'api/student_view/code', to: 'student_view#code'
  get 'api/student_view/code_string', to: 'student_view#code_string'
end
