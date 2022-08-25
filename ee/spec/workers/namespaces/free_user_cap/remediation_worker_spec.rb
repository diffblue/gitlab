# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::RemediationWorker, type: :worker do
  using RSpec::Parameterized::TableSyntax

  describe '#perform' do
    before do
      stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
      stub_const('Namespaces::FreeUserCap::RemediationWorker::MAX_NAMESPACES_TO_TRIM', 2)
    end

    context 'when on gitlab.com', :saas do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when feature flags are on' do
        before do
          stub_feature_flags(
            free_user_cap_data_remediation_job: true,
            free_user_cap: true
          )
        end

        it 'remediates data and settings according to free plan guidelines' do
          g1 = create(:group_with_plan, :private, plan: :free_plan)
          g2 = create(:group_with_plan, :private, plan: :free_plan)
          g3 = create(:group_with_plan, :private, plan: :free_plan)
          g4 = create(:group_with_plan, :private, plan: :premium_plan)
          g5 = create(:group, :private)
          # the below namespace should not be remediated since it is a personal namespace
          g7 = create(:namespace_with_plan, plan: :free_plan)
          p1_for_g7 = create(:project, namespace: g7)
          # the below namespace should not be remediated since it is a public namespace
          g8 = create(:group, :public)

          namespaces = [g1, g2, g3, g4, g5, g8]
          namespaces.each.with_index do |g, i|
            create_list(:group_member, i + 2, :active, source: g)
          end

          namespaces << g7
          create_list(:project_member, 8, :active, project: p1_for_g7)

          # first run trims 2 namespaces: g2 and g3. g1 already within limit and is skipped
          described_class.new.perform

          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 0, 0, 0])

          # second run skips g4 trims g5 and skips trimming g7 and g8
          described_class.new.perform

          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 4, 0, 0])

          described_class.new.perform

          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 4, 0, 0])

          # fourth run finally updates g4, which is downgraded to free
          g4.gitlab_subscription.update!(hosted_plan: create(:free_plan))

          described_class.new.perform

          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 3, 4, 0, 0])

          # fifth run trims g2 which adds more members
          create_list(:group_member, 4, :active, source: g2)

          described_class.new.perform

          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 5, 2, 3, 4, 0, 0])

          # sixth run trims g8 which transitions to private
          g8.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          described_class.new.perform

          expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 5, 2, 3, 4, 5, 0])
        end
      end
    end

    context 'when an error occurs', :saas do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        stub_feature_flags(free_user_cap_data_remediation_job: true, free_user_cap: true)

        allow_next_instance_of(Namespaces::FreeUserCap::DeactivateMembersOverLimitService) do |instance|
          allow(instance).to receive(:execute).and_raise('An exception')
        end
      end

      it 'logs an error' do
        g = create(:group, :private)
        create_list(:group_member, 3, :active, group: g)

        expect(Sidekiq.logger)
          .to receive(:error)
                .with("Cannot remediate namespace with ID=#{g.id} due to: An exception in 0 run")

        described_class.new.perform
      end
    end

    context 'with feature flags and environments' do
      let_it_be(:group_1) { create(:group, :private) }
      let_it_be(:group_2) { create(:group, :private) }
      let_it_be(:namespaces) { [group_1, group_2] }

      before_all do
        create_list(:group_member, 3, :active, source: group_1)
        create_list(:group_member, 3, :active, source: group_2)
      end

      where(
        should_check_namespace_plan: [true, false],
        free_user_cap: [true, false],
        free_user_cap_data_remediation_job: [true, false]
      )
      before do
        stub_ee_application_setting(should_check_namespace_plan: should_check_namespace_plan)
        stub_feature_flags(
          free_user_cap_data_remediation_job: free_user_cap_data_remediation_job,
          free_user_cap: free_user_cap
        )
      end

      with_them do
        it 'does not remediate the namespaces', :aggregate_failures do
          described_class.new.perform

          core_flag_value = should_check_namespace_plan & free_user_cap_data_remediation_job & free_user_cap
          expect(Member.with_state(:awaiting).exists?).to be(core_flag_value)
        end
      end
    end
  end
end
