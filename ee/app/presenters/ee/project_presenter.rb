# frozen_string_literal: true

module EE
  module ProjectPresenter
    extend ::Gitlab::Utils::Override

    override :statistics_buttons
    def statistics_buttons(show_auto_devops_callout:)
      super + extra_statistics_buttons
    end

    def extra_statistics_buttons
      [sast_anchor_data.presence].compact
    end

    def approver_groups
      ::ApproverGroup.filtered_approver_groups(project.approver_groups, current_user)
    end

    private

    def sast_anchor_data
      return unless sast_entry_points_experiment_enabled?(project)

      ::ProjectPresenter::AnchorData.new(
        false,
        statistic_icon + s_('SastEntryPoints|Add Security Testing'),
        help_page_path('user/application_security/sast/index'),
        'btn-dashed js-sast-entry-point',
        nil,
        nil,
        {
          'track-event': 'cta_clicked_button',
          'track-experiment': 'sast_entry_points'
        }
      )
    end
  end
end
