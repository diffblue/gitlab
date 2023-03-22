# frozen_string_literal: true

require 'spec_helper'

# Interim feature category experimentation_activation used here while waiting for
# https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/113300 to merge
RSpec.describe Namespaces::FreeUserCap::NotifyOverLimitService, :saas, feature_category: :experimentation_activation do
  let(:frozen_time) { Time.zone.parse '2022-09-22T00:00+0' }
  let_it_be(:lower_limit) { 2 }
  let_it_be(:namespace) do
    create(:group_with_plan, :private, plan: :free_plan).tap do |record|
      create_list :group_member, lower_limit + 1, :active, source: record
      record.add_owner create(:user)
    end
  end

  around do |example|
    travel_to(frozen_time) { example.run }
  end

  before do
    # Change the limit after setup to avoid validation errors during setup
    # - We need to create namespaces that are over the limit which isn't possible
    #   anymore with net-new namespaces
    stub_ee_application_setting dashboard_limit: limit
    stub_ee_application_setting dashboard_enforcement_limit: limit
    stub_ee_application_setting dashboard_limit_enabled: true
    stub_ee_application_setting should_check_namespace_plan: true
  end

  context 'with over limit namespace' do
    let(:limit) { lower_limit }

    describe '#execute' do
      it 'records the time of notification in free_user_cap_over_limit_notified_at' do
        expect { described_class.new(root_namespace: namespace).execute }
          .to change { namespace.namespace_details.free_user_cap_over_limit_notified_at }
                .from(nil)
                .to(frozen_time)
      end
    end

    describe '.execute' do
      subject(:service) { described_class.execute root_namespace: namespace }

      it 'emails the owner(s) of the namespace' do
        namespace.owners.each do |owner|
          expect(Notify)
            .to receive(:over_free_user_limit_email).with(owner, namespace, frozen_time).once.and_call_original
        end

        service
      end

      context 'with error handling' do
        it 'rescues to a ServiceResponse' do
          expect(Namespaces::FreeUserCap)
            .to receive(:over_user_limit_mails_enabled?).and_raise(described_class::ServiceError, 'How error doing?')

          expect(service).to be_a(ServiceResponse)
          expect(service).not_to be_success
        end
      end
    end
  end

  context 'when under the limit' do
    let(:limit) { 42 }

    describe '#execute' do
      it 'exits early' do
        expect(Notify).not_to receive(:over_free_user_limit_email)

        result = described_class.new(root_namespace: namespace).execute

        expect(result).to be_nil
      end
    end
  end
end
