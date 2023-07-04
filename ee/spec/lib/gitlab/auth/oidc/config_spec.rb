# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::Config, feature_category: :system_access do
  let(:gitlab_attributes) { {} }
  let(:oidc_provider_name) { 'openid_connect' }
  let(:openid_connect_omniauth_config) do
    {
      'name' => 'openid_connect',
      'args' => {
        'name' => oidc_provider_name,
        'client_options' => {
          'gitlab' => gitlab_attributes
        }
      }
    }
  end

  before do
    allow(Gitlab::Auth::OAuth::Provider).to receive_messages({ config_for: openid_connect_omniauth_config })
  end

  subject(:config) { described_class.options_for(oidc_provider_name) }

  describe '#groups_attribute' do
    context 'when config is defined' do
      let(:config_value) { 'GroupNames' }
      let(:gitlab_attributes) { { 'groups_attribute' => config_value } }

      it 'returns the value' do
        expect(config.groups_attribute).to eq(config_value)
      end
    end

    context 'when config is not defined' do
      it 'returns default value' do
        expect(config.groups_attribute).to eq('groups')
      end
    end
  end

  describe '#required_groups' do
    context 'when config is defined' do
      let(:config_value) { 'Login' }
      let(:gitlab_attributes) { { 'required_groups' => config_value } }

      it 'returns the value' do
        expect(config.required_groups).to eq(config_value)
      end
    end

    context 'when config is not defined' do
      it 'returns empty array' do
        expect(config.required_groups).to eq([])
      end
    end
  end

  describe '#admin_groups' do
    context 'when config is defined' do
      let(:config_value) { 'ArchitectureAstronauts' }
      let(:gitlab_attributes) { { 'admin_groups' => config_value } }

      it 'returns the value' do
        expect(config.admin_groups).to eq(config_value)
      end
    end

    context 'when config is not defined' do
      it 'returns empty array' do
        expect(config.admin_groups).to eq([])
      end
    end
  end

  describe '#auditor_groups' do
    context 'when config is defined' do
      let(:config_value) { 'SeeNoEvil' }
      let(:gitlab_attributes) { { 'auditor_groups' => config_value } }

      it 'returns the value' do
        expect(config.auditor_groups).to eq(config_value)
      end
    end

    context 'when config is not defined' do
      it 'returns empty array' do
        expect(config.auditor_groups).to eq([])
      end
    end
  end

  describe '#external_groups' do
    context 'when config is defined' do
      let(:config_value) { 'Cats' }
      let(:gitlab_attributes) { { 'external_groups' => config_value } }

      it 'returns the value' do
        expect(config.external_groups).to eq(config_value)
      end
    end

    context 'when config is not defined' do
      it 'returns empty array' do
        expect(config.external_groups).to eq([])
      end
    end
  end
end
