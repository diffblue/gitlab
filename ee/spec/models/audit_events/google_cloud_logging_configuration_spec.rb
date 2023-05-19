# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::GoogleCloudLoggingConfiguration, feature_category: :audit_events do
  subject(:google_cloud_logging_config) { build(:google_cloud_logging_configuration) }

  describe 'Associations' do
    it 'belongs to a group' do
      expect(google_cloud_logging_config.group).to be_kind_of(Group)
    end
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:google_project_id_name) }
    it { is_expected.to validate_presence_of(:client_email) }
    it { is_expected.to validate_presence_of(:log_id_name) }
    it { is_expected.to validate_presence_of(:private_key) }

    it { is_expected.to validate_length_of(:google_project_id_name).is_at_least(6).is_at_most(30) }
    it { is_expected.to validate_length_of(:client_email).is_at_most(254) }
    it { is_expected.to validate_length_of(:log_id_name).is_at_most(511) }

    it { is_expected.to allow_value('valid-project-id').for(:google_project_id_name) }
    it { is_expected.not_to allow_value('invalid_project_id').for(:google_project_id_name) }
    it { is_expected.not_to allow_value('invalid-project-id-').for(:google_project_id_name) }
    it { is_expected.not_to allow_value('Invalid-project-id').for(:google_project_id_name) }
    it { is_expected.not_to allow_value('1-invalid-project-id').for(:google_project_id_name) }

    it { is_expected.to allow_value('valid@example.com').for(:client_email) }
    it { is_expected.to allow_value('valid@example.org').for(:client_email) }
    it { is_expected.to allow_value('valid@example.co.uk').for(:client_email) }
    it { is_expected.to allow_value('valid_email+mail@mail.com').for(:client_email) }
    it { is_expected.not_to allow_value('invalid_email').for(:client_email) }
    it { is_expected.not_to allow_value('invalid@.com').for(:client_email) }
    it { is_expected.not_to allow_value('invalid..com').for(:client_email) }

    it { is_expected.to allow_value('audit_events').for(:log_id_name) }
    it { is_expected.to allow_value('audit-events').for(:log_id_name) }
    it { is_expected.to allow_value('audit.events').for(:log_id_name) }
    it { is_expected.to allow_value('AUDIT_EVENTS').for(:log_id_name) }
    it { is_expected.to allow_value('audit_events/123').for(:log_id_name) }
    it { is_expected.not_to allow_value('AUDIT_EVENT@').for(:log_id_name) }
    it { is_expected.not_to allow_value('AUDIT_EVENT$').for(:log_id_name) }
    it { is_expected.not_to allow_value('#AUDIT_EVENT').for(:log_id_name) }
    it { is_expected.not_to allow_value('%audit_events/123').for(:log_id_name) }

    context 'when the same google_project_id_name for the same namespace and log_id_name exists' do
      let(:group) { create(:group) }
      let(:google_project_id_name) { 'valid-project-id' }
      let(:log_id_name) { 'audit_events' }

      before do
        create(:google_cloud_logging_configuration, group: group, google_project_id_name: google_project_id_name,
          log_id_name: log_id_name)
      end

      it 'is not valid and adds an error message' do
        config = build(:google_cloud_logging_configuration, group: group,
          google_project_id_name: google_project_id_name, log_id_name: log_id_name)
        expect(config).not_to be_valid
        expect(config.errors[:google_project_id_name]).to include('has already been taken')
      end
    end

    context 'when the group is a subgroup' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: group) }

      before do
        google_cloud_logging_config.group = subgroup
      end

      it 'is not valid and adds an error message' do
        expect(google_cloud_logging_config).not_to be_valid
        expect(google_cloud_logging_config.errors[:group]).to include('must not be a subgroup')
      end
    end
  end

  describe 'default values' do
    it "uses 'audit_events' as default value for log_id_name" do
      expect(described_class.new.log_id_name).to eq('audit_events')
    end
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:google_cloud_logging_configuration, group: create(:group)) }
  end
end
