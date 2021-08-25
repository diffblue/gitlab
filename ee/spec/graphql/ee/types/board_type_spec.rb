# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Board'] do
  it 'includes the ee specific fields' do
    expect(described_class).to have_graphql_fields(
      :assignee, :epics, :hide_backlog_list, :hide_closed_list, :labels, :milestone, :iteration, :iteration_cadence, :weight
    ).at_least
  end
end
