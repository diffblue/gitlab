# frozen_string_literal: true

module EE
  module RemoteMirrorEntity
    extend ActiveSupport::Concern

    prepended do
      expose :only_protected_branches

      expose :mirror_branch_regex
    end
  end
end
