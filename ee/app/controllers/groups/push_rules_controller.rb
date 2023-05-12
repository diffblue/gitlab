# frozen_string_literal: true

class Groups::PushRulesController < Groups::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include PushRulesHelper

  layout 'group'

  before_action :check_push_rules_available!
  before_action :push_rule

  respond_to :html

  feature_category :source_code_management

  def update
    service_response = PushRules::CreateOrUpdateService
      .new(container: group, current_user: current_user, params: push_rule_params)
      .execute

    if service_response.success?
      flash[:notice] = _('Push Rule updated successfully.')
    else
      flash[:alert] = service_response.message
    end

    redirect_to group_settings_repository_path(group, anchor: 'js-push-rules')
  end

  private

  def push_rule_params
    allowed_fields = %i[deny_delete_tag delete_branch_regex commit_message_regex commit_message_negative_regex
                        branch_name_regex force_push_regex author_email_regex
                        member_check file_name_regex max_file_size prevent_secrets]

    if can?(current_user, :change_reject_unsigned_commits, group)
      allowed_fields << :reject_unsigned_commits
    end

    if can?(current_user, :change_commit_committer_check, group)
      allowed_fields << :commit_committer_check
    end

    if can?(current_user, :change_commit_committer_name_check, group)
      allowed_fields << :commit_committer_name_check
    end

    if can?(current_user, :change_reject_non_dco_commits, group)
      allowed_fields << :reject_non_dco_commits
    end

    params.require(:push_rule).permit(allowed_fields)
  end

  def push_rule
    strong_memoize(:push_rule) do
      group.push_rule || group.build_push_rule
    end
  end

  def check_push_rules_available!
    render_404 unless can_modify_group_push_rules?(current_user, group)
  end
end
