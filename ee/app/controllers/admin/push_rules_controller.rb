# frozen_string_literal: true

class Admin::PushRulesController < Admin::ApplicationController
  before_action :check_push_rules_available!
  before_action :push_rule
  before_action :set_application_setting

  respond_to :html

  feature_category :source_code_management

  def show
  end

  def update
    @push_rule.update(push_rule_params)

    if @push_rule.valid?
      link_push_rule_to_application_settings
      redirect_to admin_push_rule_path, notice: _('Push Rule updated successfully.')
    else
      render :show
    end
  end

  private

  def check_push_rules_available!
    render_404 unless License.feature_available?(:push_rules)
  end

  def push_rule_params
    allowed_fields = %i[deny_delete_tag delete_branch_regex commit_message_regex commit_message_negative_regex
                        branch_name_regex force_push_regex author_email_regex
                        member_check file_name_regex max_file_size prevent_secrets]

    if @push_rule.available?(:reject_unsigned_commits)
      allowed_fields << :reject_unsigned_commits
    end

    if @push_rule.available?(:commit_committer_check)
      allowed_fields << :commit_committer_check
    end

    if @push_rule.available?(:commit_committer_name_check)
      allowed_fields << :commit_committer_name_check
    end

    if @push_rule.available?(:reject_non_dco_commits)
      allowed_fields << :reject_non_dco_commits
    end

    params.require(:push_rule).permit(allowed_fields)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def push_rule
    @push_rule ||= PushRule.find_or_initialize_by(is_sample: true)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def set_application_setting
    @application_setting = ApplicationSetting.current_without_cache
  end

  def link_push_rule_to_application_settings
    return if @application_setting.push_rule_id

    @application_setting.update(push_rule_id: @push_rule.id)
  end
end
