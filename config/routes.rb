Rails.application.routes.draw do
  get 'api/students_table_items', to: 'students_table#index'

  get 'api/student_view', to: 'student_view#index'
  get 'api/student_view/file_list', to: 'student_view#file_list'
  
end
