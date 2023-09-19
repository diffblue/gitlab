# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::ProjectIntegrationBasic, feature_category: :integrations do
  let_it_be(:integration) { create(:jenkins_integration) }

  let(:entity) do
    API::Entities::ProjectIntegrationBasic.new(integration)
  end

  subject(:representation) { entity.as_json }

  it 'exposes vulnerability_events' do
    expect(representation[:vulnerability_events]).to eq(integration.vulnerability_events)
  end
end
