# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Epics
        module Constants
          ISSUE_TYPE = :issue
          EPIC_TYPE = :epic

          CLOSED_ISSUE_STATE = Issue.available_states[:closed].freeze
          OPENED_ISSUE_STATE = Issue.available_states[:opened].freeze

          CLOSED_EPIC_STATE = Epic.available_states[:closed].freeze
          OPENED_EPIC_STATE = Epic.available_states[:opened].freeze

          ON_TRACK_STATUS = Issue.health_statuses[:on_track].freeze
          NEEDS_ATTENTION_STATUS = Issue.health_statuses[:needs_attention].freeze
          AT_RISK_STATUS = Issue.health_statuses[:at_risk].freeze

          COUNT = :count
          WEIGHT_SUM = :weight_sum
          HEALTH_STATUS_SUM = :health_status_sum
        end
      end
    end
  end
end
