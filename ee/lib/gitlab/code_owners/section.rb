# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Section
      DEFAULT = 'codeowners'

      attr_reader :name, :optional, :approvals, :default_owners

      def initialize(name:, optional: false, approvals: 0, default_owners: nil)
        @name = name
        @optional = optional
        @approvals = approvals
        @default_owners = default_owners.to_s.strip
      end
    end
  end
end
