# frozen_string_literal: true

module Projects
  class TargetBranchRulesController < Projects::ApplicationController
    feature_category :code_review_workflow
    urgency :low

    before_action do
      render_404 unless can?(current_user, :read_target_branch_rule, @project)
    end

    def index
      service = ::TargetBranchRules::FindService.new(@project, current_user)

      render json: { target_branch: service.execute(params[:branch_name]) }.to_json
    end

    def create
      result = TargetBranchRules::CreateService.new(@project, current_user, create_params).execute

      if result[:status] == :success
        redirect_to(project_settings_merge_requests_path(@project, anchor: 'target-branch-rules'),
          notice: _('Target branch rule created.'))
      else
        redirect_to(project_settings_merge_requests_path(@project, anchor: 'target-branch-rules'),
          alert: result[:message].join(', '))
      end
    end

    def destroy
      result = TargetBranchRules::DestroyService.new(@project, current_user, params).execute

      if result[:status] == :success
        redirect_to(project_settings_merge_requests_path(@project, anchor: 'target-branch-rules'),
          notice: _('Target branch rule deleted.'))
      else
        redirect_to(project_settings_merge_requests_path(@project, anchor: 'target-branch-rules'),
          alert: result[:message])
      end
    end

    private

    def create_params
      params.require(:projects_target_branch_rule).permit(:name, :target_branch)
    end
  end
end
