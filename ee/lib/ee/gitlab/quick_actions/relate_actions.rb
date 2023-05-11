# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module RelateActions
        extend ActiveSupport::Concern
        include ::Gitlab::QuickActions::Dsl

        included do
          desc { _('Specifies that this issue blocks other issues') }
          explanation do |target_issues|
            format(_("Set this issue as blocking %{target}."), target: target_issues.to_sentence)
          end
          execution_message do |target_issues|
            format(_("Marked %{target} as blocked by this issue."), target: target_issues.to_sentence)
          end
          params '<#issue | group/project#issue | issue URL>'
          types Issue
          condition { can_block_issues? }
          parse_params { |issues| format_params(issues) }
          command :blocks do |target_issues|
            create_links(target_issues, type: 'blocks')
          end

          desc { _('Mark this issue as blocked by other issues') }
          explanation do |target_issues|
            format(_("Set this issue as blocked by %{target}."), target: target_issues.to_sentence)
          end
          execution_message do |target_issues|
            format(_("Marked this issue as blocked by %{target}."), target: target_issues.to_sentence)
          end
          params '<#issue | group/project#issue | issue URL>'
          types Issue
          condition { can_block_issues? }
          parse_params { |issues| format_params(issues) }
          command :blocked_by do |target_issues|
            create_links(target_issues, type: 'is_blocked_by')
          end
        end

        private

        def can_block_issues?
          License.feature_available?(:blocked_issues) && can_relate_issues?
        end
      end
    end
  end
end
