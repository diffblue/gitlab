# frozen_string_literal: true

module EE
  module MirrorHelper
    extend ::Gitlab::Utils::Override

    override :mirrors_form_data_attributes
    def mirrors_form_data_attributes
      super.merge(mirror_only_branches_match_regex_enabled: ::Feature.enabled?(:mirror_only_branches_match_regex, @project) && @project.licensed_feature_available?(:repository_mirrors))
    end

    def render_mirror_failed_message(raw_message:)
      mirror_last_update_at = @project.import_state.last_update_at
      message = "Pull mirroring failed #{time_ago_with_tooltip(mirror_last_update_at)}.".html_safe

      return message if raw_message

      message = sprite_icon('warning-solid') + ' ' + message

      if can?(current_user, :admin_project, @project)
        link_to message, project_mirror_path(@project)
      else
        message
      end
    end

    def branch_diverged_tooltip_message
      message = [s_('Branches|The branch could not be updated automatically because it has diverged from its upstream counterpart.')]

      if can?(current_user, :push_code, @project)
        message << '<br>'
        message << s_("Branches|To discard the local changes and overwrite the branch with the upstream version, delete it here and choose 'Update Now' above.")
      end

      message.join
    end

    def mirrored_repositories_count(project = @project)
      count = project.mirror == true ? 1 : 0
      count + @project.remote_mirrors.to_a.count { |mirror| mirror.enabled }
    end

    def mirror_branches_text(record)
      case record.mirror_branches_setting
      when 'all'
        _('All branches')
      when 'protected'
        _('All protected branches')
      when 'regex'
        _('Specific branches')
      end
    end
  end
end
