# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of external audit event destinations for the instance', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:destination_1) { create(:instance_google_cloud_logging_configuration) }
  let_it_be(:destination_2) { create(:instance_google_cloud_logging_configuration) }

  let(:path) { %i[instance_google_cloud_logging_configurations nodes] }

  let(:query) do
    graphql_query_for(
      :instance_google_cloud_logging_configurations
    )
  end

  shared_examples 'a request that returns no destinations' do
    it 'returns no destinations' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:instance_google_cloud_logging_configurations, :nodes)).to be_empty
    end
  end

  context 'when user is authenticated' do
    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when user is instance admin' do
        it 'returns the instance external audit event destinations', :aggregate_failures do
          post_graphql(query, current_user: admin)

          expect(graphql_data_at(*path)).to contain_exactly(
            a_hash_including(
              'googleProjectIdName' => destination_1.google_project_id_name,
              'clientEmail' => destination_1.client_email,
              'logIdName' => destination_1.log_id_name,
              'name' => destination_1.name
            ),
            a_hash_including(
              'googleProjectIdName' => destination_2.google_project_id_name,
              'clientEmail' => destination_2.client_email,
              'logIdName' => destination_2.log_id_name,
              'name' => destination_2.name
            )
          )

          expect(graphql_data_at(*path))
            .to contain_exactly(
              hash_not_including('private_key'),
              hash_not_including('private_key')
            )
        end
      end

      context 'when user is not instance admin' do
        it_behaves_like 'a request that returns no destinations' do
          let(:current_user) { user }
        end
      end
    end

    context 'when feature is not licensed' do
      context 'when user is instance admin' do
        it_behaves_like 'a request that returns no destinations' do
          let(:current_user) { admin }
        end
      end

      context 'when user is not instance admin' do
        it_behaves_like 'a request that returns no destinations' do
          let(:current_user) { user }
        end
      end
    end
  end

  context 'when user is not authenticated' do
    let(:user) { nil }

    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      it_behaves_like 'a request that returns no destinations' do
        let(:current_user) { user }
      end
    end

    context 'when feature is not licensed' do
      it_behaves_like 'a request that returns no destinations' do
        let(:current_user) { user }
      end
    end
  end
end
