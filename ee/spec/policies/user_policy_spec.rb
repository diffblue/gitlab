# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPolicy do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, user) }

  shared_examples 'changing a user' do |ability|
    context 'when a regular user tries to update another regular user' do
      it { is_expected.not_to be_allowed(ability) }
    end

    context 'when a regular user tries to update themselves' do
      let(:current_user) { user }

      it { is_expected.to be_allowed(ability) }
    end

    context 'when an admin user tries to update a regular user' do
      let(:current_user) { create(:user, :admin) }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(ability) }
      end

      context 'when admin mode disabled' do
        it { is_expected.not_to be_allowed(ability) }
      end
    end

    context 'when an admin user tries to update a ghost user' do
      let(:current_user) { create(:user, :admin) }
      let(:user) { create(:user, :ghost) }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.not_to be_allowed(ability) }
      end

      context 'when admin mode disabled' do
        it { is_expected.not_to be_allowed(ability) }
      end
    end
  end

  describe "updating a user's name" do
    context 'when `disable_name_update_for_users` feature is available' do
      before do
        stub_licensed_features(disable_name_update_for_users: true)
      end

      context 'when the ability to update their name is not disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: false)
        end

        it_behaves_like 'changing a user', :update_name
      end

      context 'when the ability to update their name is disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: true)
        end

        context 'for a regular user' do
          it { is_expected.not_to be_allowed(:update_name) }
        end

        context 'for a ghost user' do
          let(:current_user) { create(:user, :ghost) }

          it { is_expected.not_to be_allowed(:update_name) }
        end

        context 'for an admin user' do
          let(:current_user) { create(:admin) }

          context 'when admin mode enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:update_name) }
          end

          context 'when admin mode disabled' do
            it { is_expected.not_to be_allowed(:update_name) }
          end

          context 'when admin mode is disabled, and then enabled following sessionless login' do
            def policy
              # method, because we want a fresh cache each time.
              described_class.new(current_user, user)
            end

            it 'changes from prevented to allowed', :request_store do
              expect { Gitlab::Auth::CurrentUserMode.bypass_session!(current_user.id) }
                .to change { policy.allowed?(:update_name) }.from(false).to(true)
            end
          end
        end
      end
    end

    context 'when `disable_name_update_for_users` feature is not available' do
      before do
        stub_licensed_features(disable_name_update_for_users: false)
      end

      it_behaves_like 'changing a user', :update_name
    end
  end

  describe ':destroy_user' do
    context 'when user is not self', :enable_admin_mode do
      let(:current_user) { create(:user, :admin) }

      it { is_expected.to be_allowed(:destroy_user) }
    end

    context 'when user is self' do
      let(:current_user) { user }

      it { is_expected.to be_allowed(:destroy_user) }

      context 'when the user password is automatically set' do
        before do
          current_user.update!(password_automatically_set: true)
        end

        it { is_expected.to be_allowed(:destroy_user) }

        context 'on GitLab.com' do
          before do
            allow(::Gitlab).to receive(:com?).and_return(true)
          end

          it { is_expected.not_to be_allowed(:destroy_user) }
        end
      end
    end
  end

  describe ':create_user_personal_access_token' do
    subject { described_class.new(current_user, current_user) }

    context 'when personal access tokens are disabled' do
      before do
        stub_ee_application_setting(personal_access_tokens_disabled?: true)
      end

      it { is_expected.to be_disallowed(:create_user_personal_access_token) }
    end
  end
end
