# frozen_string_literal: true

require 'spec_helper'

# Interim feature category experimentation_activation used here while waiting for
# https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/113300 to merge
RSpec.describe Namespaces::FreeUserCap::ClearOverLimitNotificationService, :saas, feature_category: :experimentation_activation do
  describe '.execute' do
    let(:frozen_time) { Time.zone.parse "1984-09-04T00:00+0" }
    let_it_be(:namespace) { create :group_with_plan, :private, plan: :free_plan }
    let(:details) { namespace.namespace_details }

    subject(:service) { described_class.execute root_namespace: namespace }

    around do |example|
      travel_to(frozen_time) { example.run }
    end

    before do
      details.update! free_user_cap_over_limit_notified_at: (frozen_time - 42.days)
    end

    context 'with namespace that is still over limit' do
      it 'keeps the flag as is' do
        expect_next_instance_of(::Namespaces::FreeUserCap::Enforcement, namespace) do |enforce|
          expect(enforce).to receive(:over_limit?).and_return(true)
        end

        expect(service).to be_success
        expect(details.reload.free_user_cap_over_limit_notified_at).to eq(Time.zone.parse("1984-07-24T00:00+0"))
      end
    end

    context 'with namespace that is no longer over limit' do
      it 'clears the flag' do
        expect(service).to be_success
        expect(details.reload.free_user_cap_over_limit_notified_at).to be_nil
      end
    end

    context 'for error handling' do
      it 'rescues to a ServiceResponse' do
        expect_next_instance_of(Namespaces::FreeUserCap::Enforcement) do |enforcement|
          expect(enforcement).to receive(:over_limit?).and_raise(described_class::ServiceError, 'How error doing?')
        end

        expect(service).to be_a(ServiceResponse)
        expect(service).not_to be_success
      end
    end
  end
end
