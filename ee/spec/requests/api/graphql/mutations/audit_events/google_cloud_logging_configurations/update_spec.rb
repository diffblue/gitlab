# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update Google Cloud logging configuration', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:config) { create(:google_cloud_logging_configuration) }
  let_it_be(:group) { config.group }
  let_it_be(:owner) { create(:user) }
  let_it_be(:updated_google_project_id_name) { 'updated-project' }
  let_it_be(:updated_client_email) { 'updated-email@example.com' }
  let_it_be(:updated_private_key) { OpenSSL::PKey::RSA.new(4096).to_pem }
  let_it_be(:updated_log_id_name) { 'updated_log_id_name' }
  let_it_be(:config_gid) { global_id_of(config) }

  let(:current_user) { owner }
  let(:mutation) { graphql_mutation(:google_cloud_logging_configuration_update, input) }
  let(:mutation_response) { graphql_mutation_response(:google_cloud_logging_configuration_update) }

  let(:input) do
    {
      id: config_gid,
      googleProjectIdName: updated_google_project_id_name,
      clientEmail: updated_client_email,
      privateKey: updated_private_key,
      logIdName: updated_log_id_name
    }
  end

  subject(:mutate) { post_graphql_mutation(mutation, current_user: owner) }

  shared_examples 'a mutation that does not update the configuration' do
    it 'does not update the configuration' do
      expect { mutate }.not_to change { config.reload.attributes }
    end

    it 'does not create audit event' do
      expect { mutate }.not_to change { AuditEvent.count }
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is a group owner' do
      before do
        group.add_owner(owner)
        allow(Gitlab::Audit::Auditor).to receive(:audit)
      end

      it 'updates the configuration' do
        mutate

        config.reload

        expect(config.google_project_id_name).to eq(updated_google_project_id_name)
        expect(config.client_email).to eq(updated_client_email)
        expect(config.private_key).to eq(updated_private_key)
        expect(config.log_id_name).to eq(updated_log_id_name)
      end

      it 'audits the update' do
        subject

        expect(Gitlab::Audit::Auditor).to have_received(:audit) do |args|
          expect(args[:name]).to eq('google_cloud_logging_configuration_updated')
          expect(args[:author]).to eq(current_user)
          expect(args[:scope]).to eq(group)
          expect(args[:target]).to eq(group)
          expect(args[:message]).to eq("Updated Google Cloud logging configuration with project id: " \
                                       "#{updated_google_project_id_name} and log id: #{updated_log_id_name}")
        end
      end

      context 'when no fields are provided for update' do
        let(:input) do
          {
            id: config_gid
          }
        end

        it_behaves_like 'a mutation that does not update the configuration'
      end

      context 'when there is error while updating' do
        before do
          allow_next_instance_of(Mutations::AuditEvents::GoogleCloudLoggingConfigurations::Update) do |mutation|
            allow(mutation).to receive(:authorized_find!).with(config_gid).and_return(config)
          end

          allow(config).to receive(:update).and_return(false)

          errors = ActiveModel::Errors.new(config).tap { |e| e.add(:base, 'error message') }
          allow(config).to receive(:errors).and_return(errors)
        end

        it 'does not update the configuration and returns the error' do
          mutate

          expect(mutation_response).to include(
            'googleCloudLoggingConfiguration' => nil,
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
      it_behaves_like 'a mutation that does not update the configuration'
    end

    context 'when current user is a group developer' do
      before do
        group.add_developer(owner)
      end

      it_behaves_like 'a mutation on an unauthorized resource'
      it_behaves_like 'a mutation that does not update the configuration'
    end

    context 'when current user is a group guest' do
      before do
        group.add_guest(owner)
      end

      it_behaves_like 'a mutation on an unauthorized resource'
      it_behaves_like 'a mutation that does not update the configuration'
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation on an unauthorized resource'
    it_behaves_like 'a mutation that does not update the configuration'
  end
end
