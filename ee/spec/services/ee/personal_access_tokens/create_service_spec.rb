# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::CreateService, feature_category: :system_access do
  shared_examples_for 'an unsuccessfully created token' do
    it { expect(create_token.success?).to be false }
    it { expect(create_token.message).to eq('Not permitted to create') }
    it { expect(token).to be_nil }
  end

  describe '#execute' do
    subject(:create_token) { service.execute }

    let(:token) { create_token.payload[:personal_access_token] }

    context 'when target user is a service account' do
      let(:target_user) { create(:user, :service_account) }
      let(:service) do
        described_class.new(current_user: current_user, target_user: target_user,
          params: params, concatenate_errors: false)
      end

      let(:valid_params) do
        { name: 'Test token', impersonation: false, scopes: [:api], expires_at: Date.today + 1.month }
      end

      context 'for instance level' do
        let(:params) { valid_params }

        context 'when the current user is an admin' do
          let(:current_user) { create(:admin) }

          it_behaves_like 'an unsuccessfully created token'

          context 'when admin mode enabled', :enable_admin_mode do
            it_behaves_like 'an unsuccessfully created token'

            context 'when the feature is licensed' do
              before do
                stub_licensed_features(service_accounts: true)
              end

              it 'creates a token successfully' do
                expect(create_token.success?).to be true
              end
            end
          end
        end
      end

      context 'for a group' do
        let(:params) { valid_params.merge(group: group) }
        let(:group) { create(:group) }
        let(:current_user) { create(:user) }

        context 'when current user is a group owner' do
          before do
            group.add_owner(current_user)
          end

          context 'when the feature is licensed' do
            before do
              stub_licensed_features(service_accounts: true)
            end

            context 'when provisioned by group' do
              before do
                target_user.provisioned_by_group_id = group.id
                target_user.save!
              end

              it 'creates a token successfully' do
                expect(create_token.success?).to be true
              end
            end

            context 'when not provisioned by group' do
              it_behaves_like 'an unsuccessfully created token'
            end
          end

          context 'when feature is not licensed' do
            before do
              stub_licensed_features(service_accounts: false)
            end

            it_behaves_like 'an unsuccessfully created token'
          end
        end

        context 'when current user is not a group owner' do
          before do
            group.add_guest(current_user)
            stub_licensed_features(service_accounts: true)
          end

          it_behaves_like 'an unsuccessfully created token'
        end
      end
    end
  end
end
