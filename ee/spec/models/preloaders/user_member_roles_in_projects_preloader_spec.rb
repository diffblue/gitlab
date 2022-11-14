# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::UserMemberRolesInProjectsPreloader do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, :in_group) }

  context 'when customizable_roles feature is not enabled on project root ancestor' do
    it 'skips preload' do
      stub_feature_flags(customizable_roles: false)
      project_member = create(:project_member, :guest, user: user, source: project)
      create(:member_role, :guest, download_code: true, members: [project_member])

      result = described_class.new(
        projects: [project],
        user: user
      ).execute

      expect(result).to eq({})
    end
  end

  context 'when customizable_roles feature is enabled on project root ancestor' do
    context 'when project has custom role with download_code: true' do
      context 'when Array of project passed' do
        it 'returns the project_id with a value array that includes :download_code' do
          project_member = create(:project_member, :guest, user: user, source: project)
          create(:member_role, :guest, download_code: true, members: [project_member])

          result = described_class.new(projects: [project], user: user).execute

          expect(result).to eq({ project.id => [:download_code] })
        end
      end

      context 'when ActiveRecord::Relation of projects passed' do
        it 'returns the project_id with a value array that includes :download_code' do
          project_member = create(:project_member, :guest, user: user, source: project)
          create(:member_role, :guest, download_code: true, members: [project_member])

          result = described_class.new(projects: Project.where(id: project.id), user: user).execute

          expect(result).to eq({ project.id => [:download_code] })
        end
      end
    end

    context 'when project namespace has a custom role with download_code: true' do
      it 'returns the project_id with a value array that includes :download_code' do
        group_member = create(:group_member, :guest, user: user, source: project.group)
        create(:member_role, :guest, download_code: true, members: [group_member])

        result = described_class.new(projects: [project], user: user).execute

        expect(result).to eq({ project.id => [:download_code] })
      end
    end

    context 'when user is a member of the project in multiple ways' do
      it 'project value array includes :download_code if any custom roles enable download_code' do
        group_member = create(:group_member, :guest, user: user, source: project.group)
        project_member = create(:project_member, :guest, user: user, source: project)
        create(:member_role, :guest, download_code: false, members: [group_member])
        create(:member_role, :guest, download_code: true, members: [project_member])

        result = described_class.new(projects: [project], user: user).execute

        expect(result).to eq({ project.id => [:download_code] })
      end
    end

    context 'when project membership has no custom role' do
      it 'returns project id with empty value array' do
        project_without_custom_role = create(:project, :private, :in_group)
        create(:project_member, :guest, user: user, source: project_without_custom_role)

        result = described_class.new(
          projects: [project_without_custom_role],
          user: user
        ).execute

        expect(result).to eq(project_without_custom_role.id => [])
      end
    end

    context 'when project membership has custom role that does not enable download_code' do
      it 'returns project id with empty value array' do
        project_without_download_code = create(:project, :private, :in_group)
        project_without_download_code_member = create(
          :project_member, :guest,
          user: user,
          source: project_without_download_code
        )
        create(
          :member_role,
          :guest,
          download_code: false,
          members: [project_without_download_code_member]
        )

        result = described_class.new(
          projects: [project_without_download_code],
          user: user
        ).execute

        expect(result).to eq(project_without_download_code.id => [])
      end
    end

    context 'when user has custom role that enables download code outside of project hierarchy' do
      it 'ignores custom role outside of project hierarchy' do
        # subgroup is within parent group of project but not above project
        subgroup = create(:group, parent: project.group)
        subgroup_member = create(:group_member, :guest, user: user, source: subgroup)
        _custom_role_outside_hierarchy = create(
          :member_role, :guest,
          members: [subgroup_member],
          download_code: true
        )

        result = described_class.new(
          projects: [project],
          user: user
        ).execute

        expect(result).to eq({ project.id => [] })
      end
    end
  end
end
