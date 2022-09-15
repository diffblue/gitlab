# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController, type: :request do
  describe 'POST #create' do
    let_it_be(:user_attrs) { build(:user).slice(:first_name, :last_name, :username, :email, :password) }

    let(:arkose_labs_params) { { arkose_labs_token: 'arkose-labs-token' } }
    let(:user_params) { { user: user_attrs }.merge(arkose_labs_params) }

    let(:json_response) do
      Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')))
    end

    subject(:request) { post user_registration_path, params: user_params }

    shared_examples 'creates the user' do
      it 'creates the user' do
        request

        created_user = User.find_by(email: user_attrs[:email])
        expect(created_user).not_to be_nil
      end
    end

    shared_examples 'renders new action with an alert flash' do
      it 'renders new action with an alert flash', :aggregate_failures do
        request

        expect(flash[:alert]).to include(_('Complete verification to sign up.'))
        expect(response).to render_template(:new)
      end
    end

    context 'when arkose labs session token verification is needed' do
      let(:verify_response) { Arkose::VerifyResponse.new(json_response) }
      let(:service_response) { ServiceResponse.success(payload: { response: verify_response }) }

      before do
        allow_next_instance_of(Arkose::TokenVerificationService) do |instance|
          allow(instance).to receive(:execute).and_return(service_response)
        end
      end

      context 'when arkose_labs_token verification succeeds' do
        it_behaves_like 'creates the user'

        it "records the user's data from Arkose Labs" do
          expect { request }.to change(UserCustomAttribute, :count).from(0)
        end
      end

      context 'when verification fails' do
        let(:service_response) { ServiceResponse.error(message: 'Captcha was not solved') }

        it_behaves_like 'renders new action with an alert flash'

        it "does not record the user's data from Arkose Labs" do
          expect(Arkose::RecordUserDataService).not_to receive(:new)

          request
        end
      end
    end

    context 'when arkose labs session token verification is skipped' do
      shared_examples 'skips verification and data recording' do
        it 'skips verification and data recording', :aggregate_failures do
          expect(Arkose::TokenVerificationService).not_to receive(:new)
          expect(Arkose::RecordUserDataService).not_to receive(:new)

          request
        end
      end

      context 'when :arkose_labs_signup_challenge feature flag is disabled' do
        before do
          stub_feature_flags(arkose_labs_signup_challenge: false)
        end

        it_behaves_like 'creates the user'

        it_behaves_like 'skips verification and data recording'
      end

      context 'when arkose_labs_token param is not present' do
        let(:arkose_labs_params) { {} }

        it_behaves_like 'renders new action with an alert flash'

        it_behaves_like 'skips verification and data recording'
      end
    end
  end
end
