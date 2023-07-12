# frozen_string_literal: true

module EE
  module API
    module Entities
      module RemoteMirror
        extend ActiveSupport::Concern

        prepended do
          expose :mirror_branch_regex
        end
      end
    end
  end
end
