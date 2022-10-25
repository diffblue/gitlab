# frozen_string_literal: true

RSpec::Matchers.define :have_aggregate do |type, facet, state, expected_value|
  match do |epic_node_result|
    aggregate_object = epic_node_result.public_send(:"aggregate_#{facet}")
    expect(aggregate_object.public_send(method_name(type, state))).to eq expected_value
  end

  failure_message do |epic_node_result|
    aggregate_object = epic_node_result.public_send(:"aggregate_#{facet}")
    aggregate_method = method_name(type, state)
    "Epic node with id #{epic_node_result.epic_id} called #{aggregate_method} on aggregate object. Value was expected to be #{expected_value} but was #{aggregate_object.send(aggregate_method)}."
  end

  def method_name(type, state)
    case type
    when ISSUE_TYPE
      return :opened_issues if state == OPENED_ISSUE_STATE

      :closed_issues
    when EPIC_TYPE
      return :opened_epics if state == OPENED_EPIC_STATE

      :closed_epics
    end
  end
end
