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
          # we need to have a concept of .com here where there is work to be done, so the callback that
          # does this work on creation/update needs skipped
          GitlabSubscription.skip_callback(:save, :after, :set_prevent_sharing_groups_outside_hierarchy)

          stub_feature_flags(
            free_user_cap_data_remediation_job: true,
            free_user_cap: true,
            free_user_cap_group_sharing_remediation: true
          )
        end

        after do
          GitlabSubscription.set_callback(:save, :after, :set_prevent_sharing_groups_outside_hierarchy)
        end

        it 'remediates data and settings according to free plan guidelines' do
          g1 = create(:group_with_plan, plan: :free_plan)

          g2 = create(:group_with_plan, plan: :free_plan)

          g2_subgroup = create(:group, parent: g2)
          internal_ggl_for_g2 = create(:group_group_link,
                                       shared_group: g2_subgroup,
                                       shared_with_group: create(:group, parent: g2))
          create(:group_group_link, shared_group: g2_subgroup, shared_with_group: create(:group))

          p1_for_g2 = create(:project, group: g2)
          internal_pgl_for_g2 = create(:project_group_link, project: p1_for_g2, group: create(:group, parent: g2))
          create(:project_group_link, project: p1_for_g2)

          g3 = create(:group_with_plan, plan: :free_plan)

          g4 = create(:group_with_plan, plan: :premium_plan)

          g4_subgroup = create(:group, parent: g4)
          internal_ggl_for_g4 = create(:group_group_link,
                                       shared_group: g4_subgroup,
                                       shared_with_group: create(:group, parent: g4))
          external_ggl_for_g4 = create(:group_group_link, shared_group: g4_subgroup, shared_with_group: create(:group))

          p1_for_g4 = create(:project, group: g4)
          internal_pgl_for_g4 = create(:project_group_link, project: p1_for_g4, group: create(:group, parent: g4))
          external_pgl_for_g4 = create(:project_group_link, project: p1_for_g4)

          g5 = create(:group)
          g7 = create(:namespace_with_plan, plan: :free_plan)
          p1_for_g7 = create(:project, namespace: g7)

          namespaces = [g1, g2, g3, g4, g5]
          namespaces.each.with_index do |g, i|
            create_list(:group_member, i + 2, :active, source: g)
          end

          namespaces << g7
          create_list(:project_member, 8, :active, project: p1_for_g7)

          # first run trims 2 namespaces: g2 and g3. g1 already within limit and is skipped
          described_class.new.perform

          aggregate_failures do
            expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 0, 0])
            expect_shared_setting_remediated(namespaces: namespaces, remediated_namespaces: [g1, g2, g3])
            expect(ProjectGroupLink.in_project(g2.all_projects)).to match_array([internal_pgl_for_g2])
            expect(GroupGroupLink.in_shared_group(g2.self_and_descendants)).to match_array([internal_ggl_for_g2])
          end

          # second run skips g4 trims g5, g7
          described_class.new.perform

          aggregate_failures do
            expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 4, 7])
            expect_shared_setting_remediated(namespaces: namespaces, remediated_namespaces: [g1, g2, g3, g5, g7])
            expect(ProjectGroupLink.in_project(g4.all_projects))
              .to match_array([internal_pgl_for_g4, external_pgl_for_g4])
            expect(GroupGroupLink.in_shared_group(g4.self_and_descendants))
              .to match_array([internal_ggl_for_g4, external_ggl_for_g4])
          end

          described_class.new.perform

          aggregate_failures do
            expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 0, 4, 7])
            expect_shared_setting_remediated(namespaces: namespaces, remediated_namespaces: [g1, g2, g3, g5, g7])
          end

          # fourth run finally updates g4, which is downgraded to free
          g4.gitlab_subscription.update!(hosted_plan: create(:free_plan))

          described_class.new.perform

          aggregate_failures do
            expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 1, 2, 3, 4, 7])
            expect_shared_setting_remediated(namespaces: namespaces,
                                             remediated_namespaces: [g1, g2, g3, g5, g7, g4])
            expect(ProjectGroupLink.in_project(g4.all_projects)).to match_array([internal_pgl_for_g4])
            expect(GroupGroupLink.in_shared_group(g4.self_and_descendants)).to match_array([internal_ggl_for_g4])
          end

          # fifth run trims g2 which adds more members
          create_list(:group_member, 4, :active, source: g2)

          described_class.new.perform

          aggregate_failures do
            expect(namespaces.map { |ns| Member.in_hierarchy(ns).awaiting.count }).to eq([0, 5, 2, 3, 4, 7])
            expect_shared_setting_remediated(namespaces: namespaces,
                                             remediated_namespaces: [g1, g2, g3, g4, g5, g7])
          end
        end

        def expect_shared_setting_remediated(namespaces:, remediated_namespaces:)
          namespaces_with_sharing_set = namespaces.select do |ns|
            sharing_set_to_true?(ns)
          end

          expect(namespaces_with_sharing_set).to match_array(remediated_namespaces)
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
        g = create(:group)
        create_list(:group_member, 3, :active, group: g)

        expect(Sidekiq.logger)
          .to receive(:error)
                .with("Cannot remediate namespace with ID=#{g.id} due to: An exception in 0 run")

        described_class.new.perform
      end
    end

    context 'with feature flags and environments' do
      let_it_be(:group_1) { create(:group) }
      let_it_be(:group_2) { create(:group) }
      let_it_be(:namespaces) { [group_1, group_2] }

      before_all do
        create_list(:group_member, 3, :active, source: group_1)
        create_list(:group_member, 3, :active, source: group_2)
      end

      where(
        should_check_namespace_plan: [true, false],
        free_user_cap: [true, false],
        free_user_cap_data_remediation_job: [true, false],
        group_sharing_remediation: [true, false]
      )
      before do
        stub_ee_application_setting(should_check_namespace_plan: should_check_namespace_plan)
        stub_feature_flags(
          free_user_cap_data_remediation_job: free_user_cap_data_remediation_job,
          free_user_cap_group_sharing_remediation: group_sharing_remediation,
          free_user_cap: free_user_cap
        )
      end

      with_them do
        it 'does not remediate the namespaces', :aggregate_failures do
          described_class.new.perform

          core_flag_value = should_check_namespace_plan & free_user_cap_data_remediation_job & free_user_cap
          expect(Member.with_state(:awaiting).exists?).to be(core_flag_value)
          expect(namespaces.all? { |ns| sharing_set_to_true?(ns) }).to be(core_flag_value & group_sharing_remediation)
        end
      end
    end

    def sharing_set_to_true?(namespace)
      namespace.reset.prevent_sharing_groups_outside_hierarchy == true
    end
  end
end
