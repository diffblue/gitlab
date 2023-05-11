# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::UserMemberRolesInProjectsPreloader, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, :in_group) }
  let_it_be(:project_member) { create(:project_member, :guest, user: user, source: project) }

  let(:project_list) { [project] }

  subject(:result) { described_class.new(projects: project_list, user: user).execute }

  context 'when custom_roles license is not enabled on project root ancestor' do
    it 'skips preload' do
      stub_licensed_features(custom_roles: false)
      create(:member_role, :guest, read_code: true, members: [project_member], namespace: project.group)

      expect(result).to eq({})
    end
  end

  context 'when custom_roles license is enabled on project root ancestor' do
    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'when project has custom role' do
      let_it_be(:member_role) do
        create(:member_role, :guest, members: [project_member], namespace: project.group, read_code: true)
      end

      context 'when custom role has read_code: true' do
        context 'when Array of project passed' do
          it 'returns the project_id with a value array that includes :read_code' do
            expect(result).to eq({ project.id => [:read_code] })
          end
        end

        context 'when ActiveRecord::Relation of projects passed' do
          let(:project_list) { Project.where(id: project.id) }

          it 'returns the project_id with a value array that includes :read_code' do
            expect(result).to eq({ project.id => [:read_code] })
          end
        end
      end
    end

    context 'when project namespace has a custom role with read_code: true' do
      let_it_be(:group_member) { create(:group_member, :guest, user: user, source: project.namespace) }
      let_it_be(:member_role) do
        create(:member_role, :guest, read_code: true, members: [group_member], namespace: project.group)
      end

      it 'returns the project_id with a value array that includes :read_code' do
        expect(result).to eq({ project.id => [:read_code] })
      end
    end

    context 'when user is a member of the project in multiple ways' do
      let_it_be(:group_member) { create(:group_member, :guest, user: user, source: project.group) }

      it 'project value array includes :read_code if any custom roles enable them' do
        create(:member_role, :guest, read_code: false, members: [project_member], namespace: project.group)
        create(:member_role, :guest, read_code: true, members: [project_member], namespace: project.group)

        expect(result[project.id]).to match_array([:read_code])
      end
    end

    context 'when project membership has no custom role' do
      let_it_be(:project) { create(:project, :private, :in_group) }

      it 'returns project id with empty value array' do
        expect(result).to eq(project.id => [])
      end
    end

    context 'when project membership has custom role that does not enable custom permission' do
      let_it_be(:project) { create(:project, :private, :in_group) }

      it 'returns project id with empty value array' do
        project_without_custom_permission_member = create(
          :project_member,
          :guest,
          user: user,
          source: project
        )
        create(
          :member_role,
          :guest,
          read_code: false,
          members: [project_without_custom_permission_member],
          namespace: project.group
        )

        expect(result).to eq(project.id => [])
      end
    end

    context 'when user has custom role that enables custom permission outside of project hierarchy' do
      it 'ignores custom role outside of project hierarchy' do
        # subgroup is within parent group of project but not above project
        subgroup = create(:group, parent: project.group)
        subgroup_member = create(:group_member, :guest, user: user, source: subgroup)
        _custom_role_outside_hierarchy = create(
          :member_role, :guest,
          members: [subgroup_member],
          read_code: true,
          namespace: project.group
        )

        expect(result).to eq({ project.id => [] })
      end
    end
  end
end
