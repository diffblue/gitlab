# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController, type: :request do
  describe 'POST #create' do
    let_it_be(:base_user_params) { build_stubbed(:user).slice(:first_name, :last_name, :username, :email, :password) }

    let(:arkose_labs_params) { { arkose_labs_token: 'arkose-labs-token' } }
    let(:user_params) { { user: base_user_params }.merge(arkose_labs_params) }

    subject(:request) { post user_registration_path, params: user_params }

    context 'when arkose_labs_token verification succeeds' do
      it 'does not render new action', :aggregate_failures do
        request

        expect(flash[:alert]).to be_nil
        expect(response).not_to render_template(:new)
      end
    end

    context 'when arkose_labs_token verification fails' do
      let(:arkose_labs_params) { {} }

      it 'renders new action with an alert flash', :aggregate_failures do
        request

        expect(flash[:alert]).to include(_('Complete verification to sign up.'))
        expect(response).to render_template(:new)
      end
    end
  end
end
