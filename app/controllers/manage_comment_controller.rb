# frozen_string_literal: true

class ManageCommentController < ApplicationController
  def save
    student_id = params[:student_id]
    commit_index = params[:commit_index].to_i
    new_comment = params[:comment]

    api_result = { status: '' }

    comment = CommentInfo.find_by(student_id: student_id, commit_index: commit_index)
    logger.debug comment

    if comment.nil?
      comment = CommentInfo.create!(student_id: student_id, commit_index: commit_index, comment: new_comment)
      api_result['status'] = if comment.save
                               # save success
                               'success'
                             else
                               # save not success
                               'failed'
                             end
      # api_result['statue'] = new_comment.save ? 'success' : 'failed'

    else
      comment.update(comment: new_comment)
      api_result['status'] = 'success'
    end
    render json: api_result
  end

  def fetch
    student_id = params[:student_id]
    commit_index = params[:commit_index].to_i

    result = { comment: '' }

    comment_info = CommentInfo.find_by(student_id: student_id, commit_index: commit_index)

    result['comment'] = comment_info.comment if comment_info.present?
    # result['comment'] = comment_info.comment if comment_info.exists?

    render json: result
  end
end
