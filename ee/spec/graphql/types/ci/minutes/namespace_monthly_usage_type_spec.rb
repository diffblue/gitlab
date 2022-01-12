# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiMinutesNamespaceMonthlyUsage'] do
  it do
    expect(described_class).to have_graphql_fields(:minutes, :month, :month_iso8601, :projects, :shared_runners_duration)
  end
end
