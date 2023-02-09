# frozen_string_literal: true

require 'spec_helper'

# Interim feature category experimentation_activation used here while waiting for
# https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/113300 to merge
RSpec.describe Namespaces::FreeUserCap::NotifyOverLimitGroupsService, feature_category: :experimentation_activation,
  saas: true do
  def create_enforcable_free_group(dashboard_limit: 2)
    free_group = create :group_with_plan, :private, plan: :free_plan
    create_list :group_member, (dashboard_limit + 1), :active, source: free_group
    free_group
  end

  let(:frozen_time) { Time.zone.parse "2022-09-22T00:00+0" }
  let(:group) { create_enforcable_free_group }

  around do |example|
    travel_to(frozen_time) { example.run }
  end

  before do
    # Change the limit after setup to avoid validation errors during setup
    # - We need to create groups that are over the limit which isn't possible
    #   anymore with net-new namespaces
    # @group = create_enforcable_free_group
    group.add_owner create(:owner)

    stub_ee_application_setting dashboard_limit: limit
    stub_ee_application_setting dashboard_enforcement_limit: limit
    stub_ee_application_setting dashboard_limit_enabled: true
    stub_ee_application_setting should_check_namespace_plan: true
  end

  context "with over limit group" do
    let(:limit) { 2 }

    describe '#execute', :saas do
      let(:service) { described_class.new group: group }

      it 'records the time of notification in free_user_cap_over_limit_notified_at' do
        expect { service.execute }
          .to change { group.namespace_details.free_user_cap_over_limit_notified_at }
          .from(nil)
          .to(Time.zone.parse("2022-09-22T00:00:00.+0"))

        service.execute
      end
    end

    describe '.execute', :saas do
      it 'emails the owner(s) of the group' do
        group.owners.each do |owner|
          expect(Notify).to receive(:over_free_user_limit_email).with(owner, group, frozen_time).once.and_call_original
        end

        described_class.execute group: group
      end
    end

    describe 'error handling', :saas do
      it 'rescues to a ServiceResponse' do
        expect(Namespaces::FreeUserCap)
          .to receive(:over_user_limit_mails_enabled?).and_raise(StandardError, 'How error doing?')
        result = described_class.execute group: group
        expect(result).to be_a(ServiceResponse)
        expect(result).not_to be_success
      end
    end
  end

  context 'when under the limit' do
    let(:limit) { 42 }

    describe '#execute', :saas do
      let(:service) { described_class.new group: group }

      it 'exits early' do
        expect(Notify).not_to receive(:over_free_user_limit_email)
        result = service.execute
        expect(result).to be_nil
      end
    end
  end
end
