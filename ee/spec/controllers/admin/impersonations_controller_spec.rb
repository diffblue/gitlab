# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ImpersonationsController do
  let(:impersonator) { create(:admin) }
  let(:user) { create(:user) }

  describe "DELETE destroy" do
    context "when signed in" do
      before do
        sign_in(user)
      end

      context "when impersonating" do
        before do
          session[:impersonator_id] = impersonator.id
          stub_licensed_features(extended_audit_events: true)
        end

        it 'enqueues a new worker' do
          expect(AuditEvents::UserImpersonationEventCreateWorker).to receive(:perform_async).with(impersonator.id, user.id, anything, 'stopped').once

          delete :destroy
        end
      end
    end
  end
end
