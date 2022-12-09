# frozen_string_literal: true

module EE
  module IssuePolicy
    extend ActiveSupport::Concern

    prepended do
      rule { can_be_promoted_to_epic }.policy do
        enable :promote_to_epic
      end
    end
  end
end
