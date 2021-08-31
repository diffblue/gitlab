# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PagesDeploymentRegistry'] do
  it_behaves_like 'a Geo registry type'

  it 'has the expected fields (other than those included in RegistryType)' do
    expected_fields = %i[pages_deployment_id]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end
end
