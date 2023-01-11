# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::ResetRegistrationTokenService, '#execute', feature_category: :runner_fleet do
  subject(:execute) { described_class.new(scope, current_user).execute }

  let_it_be(:user) { build(:user) }
  let_it_be(:admin_user) { create(:user, :admin) }

  shared_examples 'a registration token reset operation' do
    context 'without user' do
      let(:current_user) { nil }

      it 'does not audit and returns error response', :aggregate_failures do
        expect(scope).not_to receive(token_reset_method_name)
        expect(::AuditEvents::RunnersTokenAuditEventService).not_to receive(:new)

        is_expected.to be_error
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { user }

      it 'does not audit and returns error response', :aggregate_failures do
        expect(scope).not_to receive(token_reset_method_name)
        expect(::AuditEvents::RunnersTokenAuditEventService).not_to receive(:new)

        is_expected.to be_error
      end
    end

    context 'with admin user', :enable_admin_mode do
      let(:current_user) { admin_user }
      let(:audit_service) { instance_double(::AuditEvents::RunnersTokenAuditEventService) }

      before do
        expect(scope).to receive(token_reset_method_name) do
          expect(scope).to receive(token_method_name).and_return("new #{scope.class.name} token value")
          true
        end.once

        expect(::AuditEvents::RunnersTokenAuditEventService).to receive(:new)
          .with(current_user, scope, scope.public_send(token_method_name), "new #{scope.class.name} token value")
          .once.and_return(audit_service)
        expect(audit_service).to receive(:security_event).once.and_return('track_event_return_value')
      end

      it 'calls security_event on RunnersTokenAuditEventService and returns the new token', :aggregate_failures do
        expect(execute).to be_success
        expect(execute.payload[:new_registration_token]).to eq("new #{scope.class.name} token value")
      end
    end
  end

  context 'with instance scope' do
    let_it_be(:scope) { build(:application_setting) }

    before do
      allow(ApplicationSetting).to receive(:current).and_return(scope)
      allow(ApplicationSetting).to receive(:current_without_cache).and_return(scope)
    end

    it_behaves_like 'a registration token reset operation' do
      let(:token_method_name) { :runners_registration_token }
      let(:token_reset_method_name) { :reset_runners_registration_token! }
    end
  end

  context 'with group scope' do
    let_it_be(:scope) { create(:group) }

    it_behaves_like 'a registration token reset operation' do
      let(:token_method_name) { :runners_token }
      let(:token_reset_method_name) { :reset_runners_token! }
    end
  end

  context 'with project scope' do
    let_it_be(:scope) { create(:project) }

    it_behaves_like 'a registration token reset operation' do
      let(:token_method_name) { :runners_token }
      let(:token_reset_method_name) { :reset_runners_token! }
    end
  end
end
