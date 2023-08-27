# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CustomizableDashboard'], feature_category: :product_analytics_data_management do
  let(:expected_fields) do
    %i[title slug description panels user_defined configuration_project category]
  end

  subject { described_class }

  it { is_expected.to have_graphql_fields(expected_fields) }
  it { is_expected.to require_graphql_authorizations(:developer_access) }
end
