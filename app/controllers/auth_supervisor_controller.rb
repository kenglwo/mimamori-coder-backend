# frozen_string_literal: true

class AuthSupervisorController < ApplicationController
  def auth
    supervisor_password = params[:supervisor_password]
    api_result = { status: '' }

    api_result['status'] = supervisor_password == 'gosh2aHu' ? 'success' : 'fail'

    render json: api_result
  end
end
