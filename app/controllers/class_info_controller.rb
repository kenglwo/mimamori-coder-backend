class ClassInfoController < ApplicationController
  def list
    class_list = ClassInfo.all

    result = {
      class_list: class_list
    }

    render json: result

  end
end
