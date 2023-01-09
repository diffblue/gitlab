# frozen_string_literal: true

module EE
  module RemoteMirrorEntity
    extend ActiveSupport::Concern

    prepended do
      expose :only_protected_branches

      expose :mirror_branch_regex, if: proc { |mirror|
                                         ::Feature.enabled?(:mirror_only_branches_match_regex, mirror.project)
                                       }
    end
  end
end
