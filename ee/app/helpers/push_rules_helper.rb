# frozen_string_literal: true

module PushRulesHelper
  def can_modify_group_push_rules?(current_user, group)
    can?(current_user, :change_push_rules, group)
  end

  def reject_unsigned_commits_description(push_rule)
    message = s_("ProjectSettings|Only signed commits can be pushed to this repository.")

    push_rule_update_description(message, push_rule, :reject_unsigned_commits)
  end

  def reject_non_dco_commits_description(push_rule)
    message = format(s_("ProjectSettings|Only commits that include a %{code_block_start}Signed-off-by:%{code_block_end} element can be pushed to this repository.").html_safe, code_block_start: '<code>'.html_safe, code_block_end: '</code>'.html_safe)

    push_rule_update_description(message, push_rule, :reject_non_dco_commits)
  end

  def commit_committer_check_description(push_rule)
    message = s_("ProjectSettings|Users can only push commits to this repository "\
                 "if the committer email is one of their own verified emails.")

    push_rule_update_description(message, push_rule, :commit_committer_check)
  end

  def commit_committer_name_check_description(push_rule)
    message = s_("ProjectSettings|Users can only push commits to this repository "\
      "if the commit author name is consistent with their GitLab account name.")

    push_rule_update_description(message, push_rule, :commit_committer_name_check)
  end

  private

  def push_rule_update_description(message, push_rule, rule)
    messages = [message]
    if push_rule.global?
      messages << s_("ProjectSettings|This setting will be applied to all projects unless overridden by an admin.")
    else
      enabled_globally = PushRule.global&.public_send(rule)
      enabled_in_project = push_rule.public_send(rule) # rubocop:disable GitlabSecurity/PublicSend

      if enabled_globally
        messages << if enabled_in_project
                      s_("ProjectSettings|This setting is applied on the server level and can be overridden by an admin.")
                    else
                      s_("ProjectSettings|This setting is applied on the server level but has been overridden for this project.")
                    end

        unless current_user.can_admin_all_resources?
          messages << s_("ProjectSettings|Contact an admin to change this setting.")
        end
      end
    end

    messages.join(' ').html_safe
  end
end
