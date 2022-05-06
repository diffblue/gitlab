# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCapWorker, type: :worker do
  using RSpec::Parameterized::TableSyntax

  describe '#perform' do
    shared_examples 'does not call deactivation service' do
      it 'worker does not call service' do
        g1 = create(:group)
        g2 = create(:group)
        g3 = create(:group)
        g4 = create(:group)

        create_list(:group_member, 3, :active, source: g1)
        create_list(:group_member, 4, :active, source: g2)
        create_list(:group_member, 5, :active, source: g3)
        create_list(:group_member, 3, :active, source: g4)

        described_class.new.perform
      end
    end

    before do
      stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
      stub_const('Namespaces::FreeUserCapWorker::MAX_NAMESPACES_TO_TRIM', 2)
    end

    context 'when on gitlab.com' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      context 'when feature flags are on' do
        before do
          stub_feature_flags(
            free_user_cap_data_remediation_job: true,
            free_user_cap: true
          )
        end

        it 'subsequent runs deactivates members in batches with limit' do
          g1 = create(:group_with_plan, plan: :free_plan)
          g2 = create(:group_with_plan, plan: :free_plan)
          g3 = create(:group_with_plan, plan: :free_plan)
          g4 = create(:group_with_plan, plan: :premium_plan)
          g5 = create(:group)
          g6 = create(:group_with_plan, plan: :free_plan)
          g7 = create(:namespace_with_plan, plan: :free_plan)
          p1forg7 = create(:project, namespace: g7)

          namespaces = [g1, g2, g3, g4, g5, g6]
          namespaces.each.with_index do |g, i|
            create_list(:group_member, i + 2, :active, source: g)
          end

          namespaces << g7
          create_list(:project_member, 8, :active, project: p1forg7)

          # first run trims 2 namespaces: g2 and g3. g1 already within limit and is skipped
          described_class.new.perform
          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 0, 0, 0])

          # second run skips g4 trims g5, g6
          described_class.new.perform
          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 4, 5, 0])

          # third run trims g7
          described_class.new.perform
          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 4, 5, 7])

          # fourth run finally updates g4, which is downgraded to free
          g4.gitlab_subscription.update!(hosted_plan: create(:free_plan))
          described_class.new.perform
          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 3, 4, 5, 7])

          # fifth run trims g2 which adds more members
          create_list(:group_member, 4, :active, source: g2)
          described_class.new.perform
          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 5, 2, 3, 4, 5, 7])
        end
      end
    end

    context 'when an error occurs' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        allow(Gitlab).to receive(:com?).and_return(true)
        stub_feature_flags(free_user_cap_data_remediation_job: true, free_user_cap: true)

        allow_next_instance_of(Namespaces::DeactivateMembersOverLimitService) do |instance|
          allow(instance).to receive(:execute).and_raise('An exception')
        end
      end

      it 'logs an error' do
        g = create(:group)
        create_list(:group_member, 3, :active, group: g)

        expect(Sidekiq.logger)
          .to receive(:error)
                .with("Cannot remove members from namespace ID=#{g.id} due to: An exception in 0 run")

        described_class.new.perform
      end
    end

    context 'feature flags and environments' do
      where(
        should_check_namespace_plan: [true, false],
        free_user_cap_data_remediation_job: [true, false]
      )
      before do
        stub_ee_application_setting(should_check_namespace_plan: should_check_namespace_plan)
        stub_feature_flags(
          free_user_cap_data_remediation_job: free_user_cap_data_remediation_job,
          free_user_cap: false
        )
      end

      with_them { it_behaves_like 'does not call deactivation service' }
    end
  end
end
