# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::API, feature_category: :system_access do
  describe 'logging', :aggregate_failures do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { project.first_owner }

    context 'when the method is not allowed' do
      it 'logs the route and context metadata for the client' do
        expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
          expect(data.stringify_keys)
            .to include('correlation_id' => an_instance_of(String),
                        'meta.remote_ip' => an_instance_of(String),
                        'meta.client_id' => a_string_matching(%r{\Aip/.+}),
                        'route' => '/api/scim/:version/groups/:group/Users/:id')

          expect(data.stringify_keys).not_to include('meta.caller_id', 'meta.user')
        end

        allow(Gitlab::Auth::GroupSaml::Config).to receive(:enabled?).and_return(true)

        process(:put, '/api/scim/v2/groups/1/Users/foo')

        expect(response).to have_gitlab_http_status(:method_not_allowed)
      end
    end
  end
end
