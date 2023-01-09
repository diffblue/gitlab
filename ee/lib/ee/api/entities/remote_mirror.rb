# frozen_string_literal: true

module EE
  module API
    module Entities
      module RemoteMirror
        extend ActiveSupport::Concern

        prepended do
          expose :mirror_branch_regex, if: proc { |mirror|
                                             ::Feature.enabled?(:mirror_only_branches_match_regex, mirror.project)
                                           }
        end
      end
    end
  end
end
