# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::GroupDetail do
  describe 'unique_project_download_limit attributes' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    let(:feature_enabled) { true }

    subject { described_class.new(group, current_user: user).as_json }

    before do
      allow(group).to receive(:unique_project_download_limit_enabled?) { feature_enabled }

      group&.namespace_settings&.update!(
        unique_project_download_limit: 1,
        unique_project_download_limit_interval_in_seconds: 2,
        unique_project_download_limit_allowlist: [user.username]
      )
    end

    it 'exposes the attributes' do
      group.add_owner(user)

      expect(subject[:unique_project_download_limit]).to eq 1
      expect(subject[:unique_project_download_limit_interval_in_seconds]).to eq 2
      expect(subject[:unique_project_download_limit_allowlist]).to contain_exactly(user.username)
    end

    shared_examples 'does not expose the attributes' do
      it 'does not expose the attributes' do
        expect(subject.keys).not_to include(
          :unique_project_download_limit,
          :unique_project_download_limit_interval,
          :unique_project_download_limit_allowlist
        )
      end
    end

    context 'when group has no associated settings record' do
      before do
        group.add_owner(user)
        group.namespace_settings.destroy!
        group.reload
      end

      it_behaves_like 'does not expose the attributes'
    end

    context 'when feature is not enabled' do
      let(:feature_enabled) { false }

      before do
        group.add_owner(user)
      end

      it_behaves_like 'does not expose the attributes'
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it_behaves_like 'does not expose the attributes'
    end
  end
end
