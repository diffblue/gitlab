# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsersController, feature_category: :user_management do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  describe 'GET #index' do
    it 'eager loads obstacles to user deletion' do
      get :index

      expect(assigns(:users).first.association(:oncall_schedules)).to be_loaded
      expect(assigns(:users).first.association(:escalation_policies)).to be_loaded
    end
  end

  describe 'POST update' do
    context 'update custom attributes' do
      let!(:custom_attribute) { user.custom_attributes.create!(key: UserCustomAttribute::ARKOSE_RISK_BAND, value: Arkose::VerifyResponse::RISK_BAND_MEDIUM) }
      let(:params) do
        {
          id: user.to_param,
          user: {
            custom_attributes_attributes: {
              id: custom_attribute.to_param,
              value: Arkose::VerifyResponse::RISK_BAND_LOW
            }
          }
        }
      end

      it 'updates the value' do
        expect { put :update, params: params }.to change { user.arkose_risk_band }
          .from(Arkose::VerifyResponse::RISK_BAND_MEDIUM.downcase)
          .to(Arkose::VerifyResponse::RISK_BAND_LOW.downcase)

        expect(response).to redirect_to(admin_user_path(user))
      end
    end

    context 'updating name' do
      shared_examples_for 'admin can update the name of a user' do
        it 'updates the name' do
          params = {
            id: user.to_param,
            user: {
              name: 'New Name'
            }
          }

          put :update, params: params

          expect(response).to redirect_to(admin_user_path(user))
          expect(user.reload.name).to eq('New Name')
        end
      end

      context 'when `disable_name_update_for_users` feature is available' do
        before do
          stub_licensed_features(disable_name_update_for_users: true)
        end

        context 'when the ability to update their name is disabled for users' do
          before do
            stub_application_setting(updating_name_disabled_for_users: true)
          end

          it_behaves_like 'admin can update the name of a user'
        end

        context 'when the ability to update their name is not disabled for users' do
          before do
            stub_application_setting(updating_name_disabled_for_users: false)
          end

          it_behaves_like 'admin can update the name of a user'
        end
      end

      context 'when `disable_name_update_for_users` feature is not available' do
        before do
          stub_licensed_features(disable_name_update_for_users: false)
        end

        it_behaves_like 'admin can update the name of a user'
      end
    end
  end

  describe 'POST #reset_runner_minutes' do
    subject { post :reset_runners_minutes, params: { id: user } }

    before do
      allow_next_instance_of(Ci::Minutes::ResetUsageService) do |instance|
        allow(instance).to receive(:execute).and_return(clear_runners_minutes_service_result)
      end
    end

    context 'when the reset is successful' do
      let(:clear_runners_minutes_service_result) { true }

      it 'redirects to group path' do
        subject

        expect(response).to redirect_to(admin_user_path(user))
        expect(controller).to set_flash[:notice]
      end
    end
  end

  describe "POST #impersonate" do
    let_it_be(:user) { create(:user) }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    it 'enqueues a new worker' do
      expect(AuditEvents::UserImpersonationEventCreateWorker).to receive(:perform_async).with(admin.id, user.id, anything, 'started', DateTime.current).once

      post :impersonate, params: { id: user.username }
    end
  end

  describe 'POST #identity_verification_phone_exemption' do
    before do
      allow(controller).to receive(:find_routable!).and_return(user)
    end

    subject { post :identity_verification_phone_exemption, params: { id: user.to_param } }

    context 'when it is successful' do
      it 'calls create_phone_number_exemption! and redirects with a success notice' do
        expect(user).to receive(:create_phone_number_exemption!).once.and_call_original

        subject

        expect(controller).to set_flash[:notice].to(_('Phone verification exemption has been created.'))
        expect(response).to redirect_to(admin_user_path(user))
      end
    end

    context 'when it fails' do
      it 'calls create_phone_number_exemption! and redirects with an alert' do
        expect(user).to receive(:create_phone_number_exemption!).once.and_raise

        subject

        expect(controller).to set_flash[:alert].to(_('Something went wrong. Unable to create phone exemption.'))
        expect(response).to redirect_to(admin_user_path(user))
      end
    end
  end

  describe 'DELETE #destroy_identity_verification_phone_exemption' do
    before do
      allow(controller).to receive(:find_routable!).and_return(user)
    end

    subject { delete :destroy_identity_verification_phone_exemption, params: { id: user.to_param } }

    context 'when it is successful' do
      it 'calls destroy_phone_number_exemption and redirects with a success notice' do
        expect(user).to receive(:destroy_phone_number_exemption).once.and_return(instance_double(UserCustomAttribute))

        subject

        expect(controller).to set_flash[:notice].to(_('Phone verification exemption has been removed.'))
        expect(response).to redirect_to(admin_user_path(user))
      end
    end

    context 'when it fails' do
      it 'calls destroy_phone_number_exemption and redirects with an alert' do
        expect(user).to receive(:destroy_phone_number_exemption).once.and_return(false)

        subject

        expect(controller).to set_flash[:alert].to(_('Something went wrong. Unable to remove phone exemption.'))
        expect(response).to redirect_to(admin_user_path(user))
      end
    end
  end
end
