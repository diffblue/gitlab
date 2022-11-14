# frozen_string_literal: true

RSpec::Matchers.define :have_aggregate do |type, facet, state, status = nil, expected_value|
  match do |epic_node_result|
    aggregate_object = epic_node_result.public_send(:"aggregate_#{facet}")
    expect(aggregate_object.public_send(method_name(type, state, facet, status))).to eq expected_value
  end

  failure_message do |epic_node_result|
    aggregate_object = epic_node_result.public_send(:"aggregate_#{facet}")
    aggregate_method = method_name(type, state, facet, status)
    "Epic node with id #{epic_node_result.epic_id} called #{aggregate_method} on aggregate object. Value was expected to be #{expected_value} but was #{aggregate_object.send(aggregate_method)}."
  end

  def method_name(type, state, facet, status)
    case type
    when ISSUE_TYPE
      if facet == HEALTH_STATUS_SUM
        return case status
               when NEEDS_ATTENTION_STATUS
                 :issues_needing_attention
               else
                 # AT_RISK_STATUS, ON_TRACK_STATUS can be directly mapped to HealthStatusStruct attribute names
                 "issues_#{Issue.health_statuses.key(status)}".to_sym
               end
      end

      return :opened_issues if state == OPENED_ISSUE_STATE

      :closed_issues
    when EPIC_TYPE
      return :opened_epics if state == OPENED_EPIC_STATE

      :closed_epics
    end
  end
end
