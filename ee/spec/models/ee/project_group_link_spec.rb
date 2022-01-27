# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectGroupLink do
  describe '#destroy' do
    let(:project) { create(:project) }
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let!(:project_group_link) { create(:project_group_link, project: project, group: group) }

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
    end
  end
end
