# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::GroupDetail do
  describe 'unique_project_download_limit attributes', feature_category: :insider_threat do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    let(:feature_enabled) { true }

    subject { described_class.new(group, current_user: user).as_json }

    before do
      allow(group).to receive(:unique_project_download_limit_enabled?) { feature_enabled }

      group&.namespace_settings&.update!(
        unique_project_download_limit: 1,
        unique_project_download_limit_interval_in_seconds: 2,
        unique_project_download_limit_allowlist: [user.username],
        unique_project_download_limit_alertlist: [user.id],
        auto_ban_user_on_excessive_projects_download: true
      )
    end

    it 'exposes the attributes' do
      group.add_owner(user)

      expect(subject[:unique_project_download_limit]).to eq 1
      expect(subject[:unique_project_download_limit_interval_in_seconds]).to eq 2
      expect(subject[:unique_project_download_limit_allowlist]).to contain_exactly(user.username)
      expect(subject[:unique_project_download_limit_alertlist]).to contain_exactly(user.id)
      expect(subject[:auto_ban_user_on_excessive_projects_download]).to eq true
    end

    shared_examples 'does not expose the attributes' do
      it 'does not expose the attributes' do
        expect(subject.keys).not_to include(
          :unique_project_download_limit,
          :unique_project_download_limit_interval,
          :unique_project_download_limit_allowlist,
          :unique_project_download_limit_alertlist,
          :auto_ban_user_on_excessive_projects_download
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

  describe 'ip_restriction_ranges attribute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    subject { described_class.new(group, current_user: user).as_json }

    before do
      stub_licensed_features(group_ip_restriction: true)
      update_group_ip_restriction(group, user, { ip_restriction_ranges: "192.168.0.0/24,10.0.0.0/8" })
    end

    it 'exposes the attributes' do
      expect(subject[:ip_restriction_ranges]).to eq("192.168.0.0/24,10.0.0.0/8")
    end

    context 'when ip_restriction feature is not enabled' do
      before do
        stub_licensed_features(group_ip_restriction: false)
      end

      it 'does not expose ip_restriction_ranges attributes' do
        expect(subject.keys).not_to include(
          :ip_restriction_ranges
        )
      end

      context 'for instances that have the usage_ping_features activated' do
        before do
          stub_application_setting(usage_ping_enabled: true)
          stub_application_setting(usage_ping_features_enabled: true)
        end

        it 'exposes the attributes' do
          expect(subject[:ip_restriction_ranges]).to eq("192.168.0.0/24,10.0.0.0/8")
        end
      end
    end
  end

  def update_group_ip_restriction(group, user, params)
    ::Groups::UpdateService.new(group, user, params).execute
  end
end
