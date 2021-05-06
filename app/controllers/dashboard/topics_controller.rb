# frozen_string_literal: true

class Dashboard::TopicsController < Dashboard::ApplicationController
  feature_category :projects

  def index
    @topics = Projects::TopicsFinder.new(current_user: current_user, params: finder_params).execute.page(params[:page])
  end

  def sort
    @sort ||= params[:sort] || 'popularity_desc'
  end

  private

  def finder_params
    params.permit(:name).merge(sort: sort, all_available: false)
  end
end
