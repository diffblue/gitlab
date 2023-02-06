# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AbandonedTrialEmailsCronWorker, :saas, feature_category: :onboarding do
  describe "#perform" do
    let(:mail_instance) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:deactivated_user) { create(:user, :deactivated) }
    let_it_be(:owner) { create(:group_member, group: group) }
    let_it_be(:developer) { create(:group_member, :developer, group: group) }
    let_it_be(:deactivated_owner) { create(:group_member, group: group, user: deactivated_user) }
    let_it_be(:awaiting_owner) { create(:group_member, :awaiting, group: group) }
    let_it_be(:invited_developer) { create(:group_member, :invited, :developer, group: group) }
    let_it_be(:invited_owner) { create(:group_member, :invited, group: group) }
    let_it_be(:requested_developer) { create(:group_member, :access_request, :developer, group: group) }
    let_it_be(:requested_owner) { create(:group_member, :access_request, group: group) }

    let_it_be(:gitlab_subscription) do
      create(:gitlab_subscription, :active_trial, namespace: group, trial_starts_on: 11.days.ago)
    end

    subject(:worker) { described_class.new }

    context 'when there is activity in the project' do
      let_it_be(:project) { create(:project, namespace: group) }

      context 'when recent activity' do
        let_it_be(:event) { create(:event, project: project) }

        it 'does not deliver abandoned trial notification' do
          expect(Notify).not_to receive(:abandoned_trial_notification)

          worker.perform
        end
      end

      context 'when 10 days activity' do
        let_it_be(:event) { create(:event, project: project, created_at: 10.days.ago) }

        it 'does not deliver abandoned trial notification' do
          expect(Notify).not_to receive(:abandoned_trial_notification)

          worker.perform
        end
      end

      context 'when 11 days activity' do
        let_it_be(:event) { create(:event, project: project, created_at: 11.days.ago) }

        it 'delivers abandoned trial notification' do
          expect(Notify).to receive(:abandoned_trial_notification)
                        .once.with(owner.user_id).and_return(mail_instance)

          worker.perform
        end
      end
    end

    context 'when there is activity in the subproject' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:project) { create(:project, namespace: subgroup) }
      let_it_be(:event) { create(:event, project: project) }

      it 'does not deliver abandoned trial notification' do
        expect(Notify).not_to receive(:abandoned_trial_notification)

        worker.perform
      end
    end

    context 'when there is activity in another project' do
      let_it_be(:project) { create(:project, namespace: group) }
      let_it_be(:event) { create(:event) }

      it 'delivers abandoned trial notification' do
        expect(Notify).to receive(:abandoned_trial_notification)
                      .once.with(owner.user_id).and_return(mail_instance)

        worker.perform
      end
    end
  end
end
