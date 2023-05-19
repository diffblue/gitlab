# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create google cloud logging configuration', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:google_project_id_name) { 'test-project' }
  let_it_be(:client_email) { 'test-email@example.com' }
  let_it_be(:private_key) { OpenSSL::PKey::RSA.new(4096).to_pem }
  let_it_be(:default_log_id_name) { 'audit_events' }

  let(:current_user) { owner }
  let(:mutation) { graphql_mutation(:google_cloud_logging_configuration_create, input) }
  let(:mutation_response) { graphql_mutation_response(:google_cloud_logging_configuration_create) }

  let(:input) do
    {
      groupPath: group.full_path,
      googleProjectIdName: google_project_id_name,
      clientEmail: client_email,
      privateKey: private_key
    }
  end

  subject(:mutate) { post_graphql_mutation(mutation, current_user: owner) }

  shared_examples 'a mutation that does not create a configuration' do
    it 'does not destroy the configuration' do
      expect { mutate }
        .not_to change { AuditEvents::GoogleCloudLoggingConfiguration.count }
    end
  end

  shared_examples 'an unauthorized mutation that does not create a configuration' do
    it_behaves_like 'a mutation on an unauthorized resource'
    it_behaves_like 'a mutation that does not create a configuration'
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is a group owner' do
      before do
        group.add_owner(owner)
      end

      it 'resolves group by full path' do
        expect(::Group).to receive(:find_by_full_path).with(group.full_path)

        mutate
      end

      it 'creates the configuration' do
        expect { mutate }
          .to change { AuditEvents::GoogleCloudLoggingConfiguration.count }.by(1)

        config = AuditEvents::GoogleCloudLoggingConfiguration.last
        expect(config.group).to eq(group)
        expect(config.google_project_id_name).to eq(google_project_id_name)
        expect(config.client_email).to eq(client_email)
        expect(config.log_id_name).to eq(default_log_id_name)
        expect(config.private_key).to eq(private_key)
      end

      context 'when overriding log id name' do
        let_it_be(:log_id_name) { 'test-log-id' }

        let(:input) do
          {
            groupPath: group.full_path,
            googleProjectIdName: google_project_id_name,
            clientEmail: client_email,
            privateKey: private_key,
            logIdName: log_id_name
          }
        end

        it 'creates the configuration' do
          expect { mutate }
            .to change { AuditEvents::GoogleCloudLoggingConfiguration.count }.by(1)

          config = AuditEvents::GoogleCloudLoggingConfiguration.last
          expect(config.group).to eq(group)
          expect(config.google_project_id_name).to eq(google_project_id_name)
          expect(config.client_email).to eq(client_email)
          expect(config.log_id_name).to eq(log_id_name)
          expect(config.private_key).to eq(private_key)
        end
      end

      context 'when there is error while saving' do
        before do
          allow_next_instance_of(AuditEvents::GoogleCloudLoggingConfiguration) do |instance|
            allow(instance).to receive(:save).and_return(false)

            errors = ActiveModel::Errors.new(instance).tap { |e| e.add(:log_id_name, 'error message') }
            allow(instance).to receive(:errors).and_return(errors)
          end
        end

        it 'does not create the configuration and returns the error' do
          expect { mutate }
            .not_to change { AuditEvents::GoogleCloudLoggingConfiguration.count }

          expect(mutation_response).to include(
            'googleCloudLoggingConfiguration' => nil,
            'errors' => ["Log id name error message"]
          )
        end
      end
    end

    context 'when current user is a group maintainer' do
      before do
        group.add_maintainer(owner)
      end

      it_behaves_like 'an unauthorized mutation that does not create a configuration'
    end

    context 'when current user is a group developer' do
      before do
        group.add_developer(owner)
      end

      it_behaves_like 'an unauthorized mutation that does not create a configuration'
    end

    context 'when current user is a group guest' do
      before do
        group.add_guest(owner)
      end

      it_behaves_like 'an unauthorized mutation that does not create a configuration'
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'an unauthorized mutation that does not create a configuration'
  end
end
