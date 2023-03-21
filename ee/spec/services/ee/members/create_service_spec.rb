# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreateService, feature_category: :subgroups do
  let_it_be(:user) { create(:user) }
  let_it_be(:root_ancestor) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, group: root_ancestor) }
  let_it_be(:subgroup) { create(:group, parent: root_ancestor) }
  let_it_be(:subgroup_project) { create(:project, group: subgroup) }
  let_it_be(:project_users) { create_list(:user, 2) }

  let(:invites) { project_users.map(&:id).join(',') }
  let(:params) do
    {
      user_id: invites,
      access_level: Gitlab::Access::GUEST,
      invite_source: '_invite_source_'
    }
  end

  subject(:execute_service) { described_class.new(user, params.merge({ source: project })).execute }

  before_all do
    project.add_maintainer(user)

    create(:project_member, :invited, project: subgroup_project, created_at: 2.days.ago)
    create(:project_member, :invited, project: subgroup_project)
    create(:group_member, :invited, group: subgroup, created_at: 2.days.ago)
    create(:group_member, :invited, group: subgroup)
  end

  context 'with group plan observing quota limits', :saas do
    let(:plan_limits) { create(:plan_limits, daily_invites: daily_invites) }
    let(:plan) { create(:plan, limits: plan_limits) }
    let!(:subscription) do
      create(
        :gitlab_subscription,
        namespace: root_ancestor,
        hosted_plan: plan
      )
    end

    shared_examples 'quota limit exceeded' do |limit|
      it { expect(execute_service).to include(status: :error, message: "Invite limit of #{limit} per day exceeded") }
      it { expect { execute_service }.not_to change { Member.count } }
    end

    context 'already exceeded invite quota limit' do
      let(:daily_invites) { 2 }

      it_behaves_like 'quota limit exceeded', 2
    end

    context 'will exceed invite quota limit' do
      let(:daily_invites) { 3 }

      it_behaves_like 'quota limit exceeded', 3
    end

    context 'within invite quota limit' do
      let(:daily_invites) { 5 }

      it { expect(execute_service).to eq({ status: :success }) }

      it do
        execute_service

        expect(project.users).to include(*project_users)
      end
    end

    context 'infinite invite quota limit' do
      let(:daily_invites) { 0 }

      it { expect(subject).to eq({ status: :success }) }

      it do
        execute_service

        expect(project.users).to include(*project_users)
      end
    end
  end

  context 'without a plan' do
    let(:plan) { nil }

    it { expect(execute_service).to eq({ status: :success }) }

    it do
      execute_service

      expect(project.users).to include(*project_users)
    end
  end

  context 'when assigning tasks to be done' do
    let(:params) do
      {
        user_id: project_users.map(&:id).join(','),
        access_level: Gitlab::Access::DEVELOPER,
        tasks_to_be_done: %w(ci code),
        tasks_project_id: project.id,
        invite_source: '_invite_source_'
      }
    end

    context 'when passing many user ids' do
      it 'creates 2 task issues', :aggregate_failures, :sidekiq_inline do
        expect(TasksToBeDone::CreateWorker)
          .to receive(:perform_async)
          .with(anything, user.id, array_including(*project_users.map(&:id)))
          .once
          .and_call_original

        expect { execute_service }.to change { project.issues.reload.count }.by(2)

        expect(project.issues).to all have_attributes(
          project: project,
          author: user,
          assignees: match_array(project_users)
        )
      end
    end
  end

  context 'streaming audit event' do
    let(:group) { root_ancestor }
    let(:params) do
      {
        user_id: project_users.first.id,
        access_level: Gitlab::Access::GUEST,
        invite_source: '_invite_source_'
      }
    end

    it 'audits event with name' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(name: "member_created")
      ).and_call_original

      subject
    end

    include_examples 'sends streaming audit event'
  end

  context 'with seat availability concerns', :saas do
    let_it_be(:root_ancestor) { create(:group_with_plan, :private, plan: :free_plan) }
    let_it_be(:project) { create(:project, group: root_ancestor) }

    before do
      project.add_maintainer(user)
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    context 'when creating' do
      context 'when seat is available' do
        before do
          stub_ee_application_setting(dashboard_enforcement_limit: 3)
        end

        context 'with existing user that is a member in our hierarchy' do
          let(:existing_user) do
            new_project = create(:project, group: root_ancestor)
            create(:project_member, project: new_project).user
          end

          let(:invites) { "#{create(:user).id},#{existing_user.id}" }

          it 'adds the member' do
            expect(execute_service[:status]).to eq(:success)
            expect(project.users).to include existing_user
          end
        end

        context 'when under the dashboard limit' do
          it 'adds the members' do
            expect(execute_service[:status]).to eq(:success)
            expect(project.users).to include(*project_users)
          end
        end
      end

      context 'when seat is not available' do
        it 'does not add members' do
          expect(execute_service[:status]).to eq(:error)
          expect(execute_service[:message]).to match /: cannot be added since you've reached your /
          expect(project.users).not_to include(*project_users)
        end
      end
    end

    context 'when updating with no seats left' do
      let(:invites) { invited_member.invite_email }
      let(:invited_member) do
        build(:project_member, :maintainer, :invited, source: project).tap do |record|
          record.member_namespace_id = record.project.project_namespace_id
          record.save!(validate: false)
        end
      end

      before do
        stub_ee_application_setting(dashboard_enforcement_limit: 1)
      end

      it 'allows updating existing invited member' do
        expect(execute_service[:status]).to eq(:success)
        expect(invited_member.reset.access_level).to eq Gitlab::Access::GUEST
      end
    end
  end
end
