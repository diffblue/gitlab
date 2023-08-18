# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GoogleCloudLoggingConfigurationType'], feature_category: :audit_events do
  let(:fields) do
    %i[id google_project_id_name client_email log_id_name private_key name group]
  end

  specify { expect(described_class.graphql_name).to eq('GoogleCloudLoggingConfigurationType') }
  specify { expect(described_class).to have_graphql_fields(fields) }
  specify { expect(described_class).to require_graphql_authorizations(:admin_external_audit_events) }
end
