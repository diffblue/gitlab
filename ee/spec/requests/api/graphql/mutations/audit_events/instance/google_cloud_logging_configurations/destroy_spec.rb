# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroy Instance Google Cloud logging configuration', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:config) { create(:instance_google_cloud_logging_configuration) }
  let_it_be(:admin) { create(:admin) }

  let(:current_user) { admin }
  let(:mutation) { graphql_mutation(:instance_google_cloud_logging_configuration_destroy, id: global_id_of(config)) }
  let(:mutation_response) { graphql_mutation_response(:instance_google_cloud_logging_configuration_destroy) }

  subject(:mutate) { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'a mutation that does not destroy a configuration' do
    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

    it 'does not destroy the configuration' do
      expect { mutate }
        .not_to change { AuditEvents::Instance::GoogleCloudLoggingConfiguration.count }
    end

    it 'does not create audit event' do
      expect { mutate }.not_to change { AuditEvent.count }
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is instance admin' do
      before do
        allow(Gitlab::Audit::Auditor).to receive(:audit)
      end

      it 'destroys the configuration' do
        expect { mutate }
          .to change { AuditEvents::Instance::GoogleCloudLoggingConfiguration.count }.by(-1)
      end

      it 'audits the deletion' do
        subject

        expect(Gitlab::Audit::Auditor).to have_received(:audit) do |args|
          expect(args[:name]).to eq('instance_google_cloud_logging_configuration_deleted')
          expect(args[:author]).to eq(current_user)
          expect(args[:scope]).to be_an_instance_of(Gitlab::Audit::InstanceScope)
          expect(args[:target]).to eq(config)
          expect(args[:message])
            .to eq("Deleted Instance Google Cloud logging configuration with name: #{config.name} " \
                   "project id: #{config.google_project_id_name} and log id: #{config.log_id_name}")
        end
      end

      context 'when there is an error during destroy' do
        before do
          allow_next_instance_of(
            Mutations::AuditEvents::Instance::GoogleCloudLoggingConfigurations::Destroy) do |mutation|
            allow(mutation).to receive(:authorized_find!).and_return(config)
          end

          allow(config).to receive(:destroy).and_return(false)

          errors = ActiveModel::Errors.new(config).tap { |e| e.add(:base, 'error message') }
          allow(config).to receive(:errors).and_return(errors)
        end

        it 'does not destroy the configuration and returns the error' do
          expect { mutate }
            .not_to change { AuditEvents::Instance::GoogleCloudLoggingConfiguration.count }

          expect(mutation_response).to include('errors' => ['error message'])
        end
      end
    end

    context 'when current user is not instance admin' do
      let_it_be(:current_user) { create(:user) }

      it_behaves_like 'a mutation that does not destroy a configuration'
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation that does not destroy a configuration'
  end
end
