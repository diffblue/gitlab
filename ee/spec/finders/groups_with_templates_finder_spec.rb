# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsWithTemplatesFinder, :saas do
  let_it_be(:group_1, reload: true) { create(:group, name: 'group-1') }
  let_it_be(:group_2, reload: true) { create(:group, name: 'group-2') }
  let_it_be(:group_3, reload: true) { create(:group, name: 'group-3') }
  let_it_be(:group_4, reload: true) { create(:group, name: 'group-4') }

  let_it_be(:subgroup_1) { create(:group, parent: group_1, name: 'subgroup-1') }
  let_it_be(:subgroup_2) { create(:group, parent: group_2, name: 'subgroup-2') }
  let_it_be(:subgroup_3) { create(:group, parent: group_3, name: 'subgroup-3') }

  let_it_be(:subgroup_4, reload: true) { create(:group, parent: group_1, name: 'subgroup-4') }
  let_it_be(:subgroup_5) { create(:group, parent: subgroup_4, name: 'subgroup-5') }

  before do
    group_1.update!(custom_project_templates_group_id: subgroup_1.id)
    group_2.update!(custom_project_templates_group_id: subgroup_2.id)
    group_3.update!(custom_project_templates_group_id: subgroup_3.id)
    create(:project, namespace: subgroup_1)
    create(:project, namespace: subgroup_2)
    create(:project, namespace: subgroup_3)
    create(:gitlab_subscription, :ultimate, namespace: group_1)
    create(:gitlab_subscription, :premium, namespace: group_2)
  end

  describe 'without group id' do
    it 'returns all groups' do
      expect(described_class.new.execute).to contain_exactly(group_1, group_2, group_3)
    end

    context 'when namespace checked' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      it 'returns groups on ultimate/premium plan' do
        expect(described_class.new.execute).to contain_exactly(group_1, group_2)
      end

      context 'with subgroup with template' do
        before do
          subgroup_4.update!(custom_project_templates_group_id: subgroup_5.id)
          create(:project, namespace: subgroup_5)
        end

        it 'returns groups on ultimate/premium plan' do
          expect(described_class.new.execute).to contain_exactly(group_1, group_2, subgroup_4)
        end
      end
    end
  end

  describe 'with group id' do
    it 'returns given group with it descendants' do
      expect(described_class.new(group_1.id).execute).to contain_exactly(group_1)
    end

    context 'with subgroup with template' do
      before do
        subgroup_4.update!(custom_project_templates_group_id: subgroup_5.id)
        create(:project, namespace: subgroup_5)
      end

      it 'returns only chosen group' do
        expect(described_class.new(group_1.id).execute).to contain_exactly(group_1)
      end
    end

    context 'when namespace checked' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      it 'does not return the group' do
        expect(described_class.new(group_3.id).execute).to be_empty
      end

      context 'with subgroup with template' do
        before do
          subgroup_4.update!(custom_project_templates_group_id: subgroup_5.id)
          create(:project, namespace: subgroup_5)
        end

        it 'returns only chosen group' do
          expect(described_class.new(group_1.id).execute).to contain_exactly(group_1)
        end

        it 'returns only chosen subgroup' do
          expect(described_class.new(subgroup_4.id).execute).to contain_exactly(group_1, subgroup_4)
        end
      end
    end
  end
end
