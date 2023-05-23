# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroy google cloud logging configuration', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:config) { create(:google_cloud_logging_configuration) }
  let_it_be(:group) { config.group }
  let_it_be(:owner) { create(:user) }

  let(:current_user) { owner }
  let(:mutation) { graphql_mutation(:google_cloud_logging_configuration_destroy, id: global_id_of(config)) }
  let(:mutation_response) { graphql_mutation_response(:google_cloud_logging_configuration_destroy) }

  subject(:mutate) { post_graphql_mutation(mutation, current_user: owner) }

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is a group owner' do
      before do
        group.add_owner(owner)
      end

      it 'destroys the configuration' do
        expect { mutate }
          .to change { AuditEvents::GoogleCloudLoggingConfiguration.count }.by(-1)
      end

      context 'when there is an error during destroy' do
        before do
          allow_next_instance_of(Mutations::AuditEvents::GoogleCloudLoggingConfigurations::Destroy) do |mutation|
            allow(mutation).to receive(:authorized_find!).and_return(config)
          end

          allow(config).to receive(:destroy).and_return(false)

          errors = ActiveModel::Errors.new(config).tap { |e| e.add(:base, 'error message') }
          allow(config).to receive(:errors).and_return(errors)
        end

        it 'does not destroy the configuration and returns the error' do
          expect { mutate }
            .not_to change { AuditEvents::GoogleCloudLoggingConfiguration.count }

          expect(mutation_response).to include(
            'errors' => ['error message']
          )
        end
      end
    end

    context 'when current user is a group maintainer' do
      before do
        group.add_maintainer(owner)
      end

      it_behaves_like 'a mutation on an unauthorized resource'
    end

    context 'when current user is a group developer' do
      before do
        group.add_developer(owner)
      end

      it_behaves_like 'a mutation on an unauthorized resource'
    end

    context 'when current user is a group guest' do
      before do
        group.add_guest(owner)
      end

      it_behaves_like 'a mutation on an unauthorized resource'
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation on an unauthorized resource'
  end
end
