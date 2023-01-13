# frozen_string_literal: true

class Groups::EpicIssuesController < Groups::ApplicationController
  include EpicRelations

  before_action :check_epics_available!
  before_action :authorize_issue_link_association!, only: [:destroy, :update]

  feature_category :portfolio_management
  urgency :default

  def update
    result = EpicIssues::UpdateService.new(link, current_user, params[:epic]).execute

    render json: { message: result[:message] }, status: result[:http_status]
  end

  private

  def create_service
    EpicIssues::CreateService.new(epic, current_user, create_params)
  end

  def destroy_service
    EpicIssues::DestroyService.new(link, current_user)
  end

  def list_service
    EpicIssues::ListService.new(epic, current_user)
  end

  def authorize_issue_link_association!
    render_404 if link.epic != epic
  end

  def link
    @link ||= EpicIssue.find(params[:id])
  end

  def authorized_object
    'epic_relation'
  end
end
