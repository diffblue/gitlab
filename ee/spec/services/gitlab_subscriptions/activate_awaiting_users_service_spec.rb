# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::ActivateAwaitingUsersService, :saas do
  shared_examples 'skips user activation' do
    it 'does not activate users' do
      execute

      expect(member1.reload).to be_awaiting
      expect(member2.reload).to be_awaiting
    end
  end

  describe '#execute' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:free_plan) { create(:free_plan) }
    let_it_be(:ultimate_plan) { create(:ultimate_plan) }
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:member1) { create(:group_member, :awaiting, user: user1, source: namespace) }
    let_it_be(:member2) { create(:group_member, :awaiting, user: user2, source: namespace) }

    let(:current_plan) { free_plan }
    let(:free_user_cap_enabled) { true }
    let(:seats_remaining) { 2 }
    let(:gitlab_subscription) do
      create(:gitlab_subscription, hosted_plan: current_plan, seats: seats_remaining, namespace: namespace)
    end

    subject(:execute) do
      described_class.new(gitlab_subscription: gitlab_subscription, previous_plan_id: previous_plan&.id).execute
    end

    before do
      allow_next_instance_of(::Namespaces::FreeUserCap::Standard, namespace) do |instance|
        allow(instance).to receive(:feature_enabled?).and_return(free_user_cap_enabled)
      end
    end

    context 'without a previous plan' do
      let(:previous_plan) { nil }

      context 'when switching to a free plan' do
        let_it_be(:current_plan) { free_plan }

        it_behaves_like 'skips user activation'
      end

      context 'when switching to a paid plan' do
        let_it_be(:current_plan) { ultimate_plan }

        it_behaves_like 'skips user activation'
      end
    end

    context 'with a previous free plan' do
      let(:previous_plan) { free_plan }

      context 'when switching to a paid plan' do
        let_it_be_with_reload(:current_plan) { ultimate_plan }

        context 'when not a group namespace' do
          let_it_be(:namespace) { create(:namespace) }

          it_behaves_like 'skips user activation'
        end

        context 'when there are enough seats remaining' do
          it 'activates users' do
            execute

            expect(member1.reload).to be_active
            expect(member2.reload).to be_active
          end

          it 'audits the event using the automation bot user as author' do
            execute

            audit_event = AuditEvent.find_by(target_id: member1.id)
            expect(audit_event.author).to eq(User.automation_bot)
            expect(audit_event.details[:custom_message]).to eq('Changed the membership state to active')
          end

          context 'when free user cap is not enabled' do
            let(:free_user_cap_enabled) { false }

            it_behaves_like 'skips user activation'
          end
        end

        context 'when there are not enough seats remaining' do
          let(:seats_remaining) { 0 }

          it_behaves_like 'skips user activation'
        end
      end
    end

    context 'with a previous paid plan' do
      let(:previous_plan) { ultimate_plan }

      context 'changes from paid plan to free plan' do
        let(:current_plan) { free_plan }

        it_behaves_like 'skips user activation'
      end
    end
  end
end
