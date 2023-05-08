# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Workspace'], feature_category: :remote_development do
  let(:fields) do
    %i[
      id cluster_agent project_id user name namespace max_hours_before_termination
      desired_state desired_state_updated_at actual_state responded_to_agent_at
      url editor devfile_ref devfile_path devfile processed_devfile deployment_resource_version created_at updated_at
    ]
  end

  specify { expect(described_class.graphql_name).to eq('Workspace') }

  specify { expect(described_class).to have_graphql_fields(fields) }

  specify { expect(described_class).to require_graphql_authorizations(:read_workspace) }
end
