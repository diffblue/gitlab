# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemAccess::MicrosoftApplication, feature_category: :system_access do
  it { is_expected.to belong_to(:namespace).optional }

  it do
    is_expected
      .to have_one(:system_access_microsoft_graph_access_token)
            .class_name('SystemAccess::MicrosoftGraphAccessToken')
            .inverse_of(:system_access_microsoft_application)
            .with_foreign_key(:system_access_microsoft_application_id)
  end

  it 'has a bidirectional relationship' do
    application = create(:system_access_microsoft_application)
    token_obj = create(:system_access_microsoft_graph_access_token, system_access_microsoft_application: application)

    expect(application.system_access_microsoft_graph_access_token).to eq(token_obj)
    expect(application.system_access_microsoft_graph_access_token.system_access_microsoft_application)
      .to eq(application)
  end

  it 'only allows one record with nil namespace_id' do
    create(:system_access_microsoft_application, namespace_id: nil)
    conflicting_record = build(:system_access_microsoft_application, namespace_id: nil)

    expect(conflicting_record.valid?).to eq(false)
    expect(conflicting_record.errors['namespace_id']).to match_array([_('has already been taken')])
  end

  describe 'validates' do
    let_it_be(:application) { create(:system_access_microsoft_application) }

    it { is_expected.to validate_inclusion_of(:enabled).in_array([true, false]) }
    it { is_expected.to validate_uniqueness_of(:namespace_id) }
    it { is_expected.to validate_presence_of(:tenant_xid) }
    it { is_expected.to validate_presence_of(:client_xid) }
    it { is_expected.to validate_presence_of(:login_endpoint) }
    it { is_expected.to validate_presence_of(:graph_endpoint) }

    describe 'public URL attributes' do
      it 'allows valid URLs' do
        application.login_endpoint = 'https://login.microsoftonline.us'
        application.graph_endpoint = 'https://graph.microsoft.us'

        expect(application.valid?).to eq(true)
      end

      it 'does not allow localhost' do
        application.login_endpoint = 'https://localhost'
        application.graph_endpoint = 'https://localhost'

        expect(application.valid?).to eq(false)
      end
    end
  end

  describe '.instance_application' do
    it 'returns the record where namespace_id is nil' do
      create(:system_access_microsoft_application)
      instance_application = create(:system_access_microsoft_application, namespace_id: nil)

      expect(described_class.instance_application).to eq(instance_application)
    end
  end
end
