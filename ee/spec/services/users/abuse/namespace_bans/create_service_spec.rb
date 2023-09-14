# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Abuse::NamespaceBans::CreateService, feature_category: :insider_threat do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }

  let(:service) { described_class.new(user: user, namespace: namespace) }

  subject(:response) { service.execute }

  describe 'when passing a root namespace' do
    it { is_expected.to be_success }
  end

  describe 'when passing a nested namespace' do
    let(:namespace) { build(:group, :nested) }

    it 'returns an error response' do
      expect(response).to be_error
      expect(response.message).to eq('Namespace must be a root namespace')
    end
  end

  describe 'when passing an already banned user' do
    before do
      service.execute
    end

    it 'returns an error response' do
      expect(response).to be_error
      expect(response.message).to eq('User already banned from namespace')
    end
  end
end
