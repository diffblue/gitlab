# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['FindingReportsComparer'], feature_category: :vulnerability_management do
  it { expect(described_class).to have_graphql_fields(:status, :status_reason, :report) }
end
