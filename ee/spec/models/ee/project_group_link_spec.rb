# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectGroupLink do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project_group_link) { create(:project_group_link, project: project, group: group) }

  describe 'scopes' do
    describe '.in_project' do
      it 'provides correct link records' do
        create(:project_group_link)

        expect(described_class.in_project(project)).to match_array([project_group_link])
      end
    end

    describe '.not_in_group' do
      it 'provides correct link records' do
        not_shared_with_group = create(:group)
        create(:project_group_link, project: project, group: not_shared_with_group)

        expect(described_class.not_in_group(not_shared_with_group)).to match_array([project_group_link])
      end
    end
  end

  describe '#destroy' do
    let_it_be(:user) { create(:user) }

    before do
      project.add_developer(user)
    end

    shared_examples_for 'deleted related access levels' do |access_level_class|
      it "removes related #{access_level_class}" do
        expect { project_group_link.destroy! }.to change(access_level_class, :count).by(-1)
        expect(access_levels.find_by_group_id(group)).to be_nil
        expect(access_levels.find_by_user_id(user)).to be_persisted
      end
    end

    context 'protected tags' do
      let!(:protected_tag) do
        ProtectedTags::CreateService.new(
          project,
          project.first_owner,
          attributes_for(
            :protected_tag,
            create_access_levels_attributes: [{ group_id: group.id }, { user_id: user.id }]
          )
        ).execute
      end

      let(:access_levels) { protected_tag.create_access_levels }

      it_behaves_like 'deleted related access levels', ProtectedTag::CreateAccessLevel
    end

    context 'protected environments' do
      let!(:protected_environment) do
        ProtectedEnvironments::CreateService.new(
          container: project,
          current_user: project.first_owner,
          params: attributes_for(
            :protected_environment,
            deploy_access_levels_attributes: [{ group_id: group.id }, { user_id: user.id }]
          )
        ).execute
      end

      let(:access_levels) { protected_environment.deploy_access_levels }

      it_behaves_like 'deleted related access levels', ProtectedEnvironment::DeployAccessLevel

      context 'with approval rules' do
        let(:access_levels) { protected_environment.approval_rules }

        before do
          create(:protected_environment_approval_rule, protected_environment: protected_environment, group: group)
          create(:protected_environment_approval_rule, protected_environment: protected_environment, user: user)
        end

        it_behaves_like 'deleted related access levels', ::ProtectedEnvironments::ApprovalRule
      end
    end
  end
end
