# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Query'] do
  specify do
    expect(described_class).to have_graphql_fields(
      :ci_minutes_usage,
      :current_license,
      :geo_node,
      :instance_security_dashboard,
      :iteration,
      :license_history_entries,
      :vulnerabilities,
      :vulnerabilities_count_by_day,
      :vulnerability
    ).at_least
  end
end
