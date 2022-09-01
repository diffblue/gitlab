# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProjectMember do
  it { is_expected.to include_module(EE::ProjectMember) }

  it_behaves_like 'member validations' do
    let(:entity) { create(:project, group: group) }
  end

  context 'validates GMA enforcement' do
    let(:group) { create(:group_with_managed_accounts, :private) }
    let(:entity) { create(:project, namespace: group) }

    before do
      stub_feature_flags(group_managed_accounts: true)
    end

    context 'enforced group managed account enabled' do
      before do
        stub_licensed_features(group_saml: true)
      end

      it 'allows adding a user linked to the GMA account as project member' do
        user = create(:user, :group_managed, managing_group: group)
        member = entity.add_developer(user)

        expect(member).to be_valid
      end

      it 'does not allow adding a user not linked to the GMA account as project member' do
        member = entity.add_developer(create(:user))

        expect(member).not_to be_valid
        expect(member.errors.messages[:user]).to include('is not in the group enforcing Group Managed Account')
      end

      it 'allows adding a project bot' do
        member = entity.add_developer(create(:user, :project_bot))

        expect(member).to be_valid
      end
    end

    context 'enforced group managed account disabled' do
      it 'allows adding any user as project member' do
        member = entity.add_developer(create(:user))

        expect(member).to be_valid
      end
    end
  end

  describe '#group_domain_validations' do
    let(:member_type) { :project_member }
    let(:source) { create(:project, namespace: group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:nested_source) { create(:project, namespace: subgroup) }

    it_behaves_like 'member group domain validations', 'project'

    it 'does not validate personal projects' do
      unconfirmed_gitlab_user = create(:user, :unconfirmed, email: 'unverified@gitlab.com')
      member = create(:project, namespace: create(:user).namespace).add_developer(unconfirmed_gitlab_user)

      expect(member).to be_valid
    end
  end

  describe '#provisioned_by_this_group?' do
    let_it_be(:member) { build(:project_member) }

    subject { member.provisioned_by_this_group? }

    it { is_expected.to eq(false) }
  end

  describe '#state' do
    let!(:group) { create(:group) }
    let!(:project) { create(:project, group: group) }
    let!(:user) { create(:user) }

    describe '#activate!' do
      it "refreshes the user's authorized projects" do
        membership = create(:project_member, :awaiting, source: project, user: user)

        expect(user.authorized_projects).not_to include(project)

        membership.activate!

        expect(user.authorized_projects.reload).to include(project)
      end
    end

    describe '#wait!' do
      it "refreshes the user's authorized projects" do
        membership = create(:project_member, source: project, user: user)

        expect(user.authorized_projects).to include(project)

        membership.wait!

        expect(user.authorized_projects.reload).not_to include(project)
      end
    end
  end

  describe 'delete protected environment acceses cascadingly' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:environment) { create(:environment, project: project) }
    let_it_be(:protected_environment) do
      create(:protected_environment, project: project, name: environment.name)
    end

    let!(:member) { create(:project_member, project: project, user: user) }

    let!(:deploy_access) do
      create(:protected_environment_deploy_access_level, protected_environment: protected_environment, user: user)
    end

    let!(:deploy_access_for_diffent_user) do
      create(:protected_environment_deploy_access_level, protected_environment: protected_environment, user: create(:user))
    end

    let!(:deploy_access_for_group) do
      create(:protected_environment_deploy_access_level, protected_environment: protected_environment, group: create(:group))
    end

    let!(:deploy_access_for_maintainer_role) do
      create(:protected_environment_deploy_access_level, :maintainer_access, protected_environment: protected_environment)
    end

    it 'deletes associated protected environment access cascadingly' do
      expect { member.destroy! }
        .to change { ProtectedEnvironments::DeployAccessLevel.count }.by(-1)

      expect { deploy_access.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(protected_environment.reload.deploy_access_levels)
        .to include(deploy_access_for_diffent_user, deploy_access_for_group, deploy_access_for_maintainer_role)
    end

    context 'when the user is assiged to multiple protected environments in the same project' do
      let!(:other_protected_environment) { create(:protected_environment, project: project, name: 'staging') }
      let!(:other_deploy_access) { create(:protected_environment_deploy_access_level, protected_environment: other_protected_environment, user: user) }

      it 'deletes all associated protected environment accesses in the project' do
        expect { member.destroy! }
          .to change { ProtectedEnvironments::DeployAccessLevel.count }.by(-2)

        expect { deploy_access.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { other_deploy_access.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the user is assiged to multiple protected environments across different projects' do
      let!(:other_project) { create(:project) }
      let!(:other_protected_environment) { create(:protected_environment, project: other_project, name: 'staging') }
      let!(:other_deploy_access) { create(:protected_environment_deploy_access_level, protected_environment: other_protected_environment, user: user) }

      it 'deletes all associated protected environment accesses in the project' do
        expect { member.destroy! }
          .to change { ProtectedEnvironments::DeployAccessLevel.count }.by(-1)

        expect { deploy_access.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { other_deploy_access.reload }.not_to raise_error
      end
    end
  end

  describe 'post create hooks' do
    context 'when a new personal project is created' do
      it 'does not send notifications or create events for the creator of the project' do
        expect(NotificationService).not_to receive(:new)
        expect(EventCreateService).not_to receive(:new)

        create(:project, namespace: create(:user).namespace)
      end
    end

    context 'when a different user is added to a personal project as OWNER' do
      let_it_be(:project) { create(:project, namespace: create(:user).namespace) }
      let_it_be(:another_user) { create(:user) }

      it 'sends notifications and creates events for the newly added OWNER' do
        expect_next_instance_of(NotificationService) do |service|
          expect(service).to receive(:new_project_member).with(project.member(another_user))
        end

        expect_next_instance_of(EventCreateService) do |service|
          expect(service).to receive(:join_project).with(project, another_user)
        end

        project.add_owner(another_user)
      end
    end
  end

  describe '#accept_invite!' do
    let(:member) { create(:project_member, :invited) }
    let(:user) { create(:user) }

    it 'does not accept invite if group locks memberships for projects' do
      expect(member).to receive_message_chain(:source, :membership_locked?).and_return(true)

      member.accept_invite! user

      expect(member.user).to be_nil
      expect(member.invite_accepted_at).to be_nil
      expect(member.invite_token).not_to be_nil
      expect(member).not_to receive(:after_accept_invite)
    end
  end
end
