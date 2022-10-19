# frozen_string_literal: true

module EE
  module API
    module Helpers
      module RemoteMirrorsHelpers
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          params :mirror_branches_setting_ee do
            optional :mirror_branch_regex, type: String, desc: 'Determines if only matched branches are mirrored'
            mutually_exclusive :only_protected_branches, :mirror_branch_regex
          end
        end

        override :verify_mirror_branches_setting
        def verify_mirror_branches_setting(attrs, project)
          attrs[:mirror_branch_regex] = nil unless ::Feature.enabled?(:mirror_only_branches_match_regex, project)

          if attrs[:only_protected_branches]
            attrs[:mirror_branch_regex] = nil
          elsif attrs[:mirror_branch_regex].present?
            attrs[:only_protected_branches] = false
          end
        end
      end
    end
  end
end
