# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironment do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:deploy_access_levels) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:deploy_access_levels) }

    it 'can not belong to both group and project' do
      group = build(:group)
      project = build(:project)
      protected_environment = build(:protected_environment, group: group, project: project)

      expect { protected_environment.save! }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    end

    it 'must belong to one of group or project' do
      protected_environment = build(:protected_environment, group: nil, project: nil)

      expect { protected_environment.save! }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    end

    context 'group-level protected environment' do
      let_it_be(:group) { create(:group) }

      it 'passes the validation when the name is listed in the tiers' do
        protection = build(:protected_environment, name: 'production', group: group)

        expect(protection).to be_valid
      end

      it 'fails the validation when the name is not listed in the tiers' do
        protection = build(:protected_environment, name: 'customer-portal', group: group)

        expect(protection).not_to be_valid
        expect(protection.errors[:name].first).to include('must be one of environment tiers')
      end
    end
  end

  describe '#accessible_to?' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
    let(:user) { create(:user) }

    subject { protected_environment.accessible_to?(user) }

    context 'when user is admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be_truthy }
    end

    context 'when access has been granted to user' do
      before do
        create_deploy_access_level(protected_environment, user: user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when specific access has been assigned to a group' do
      let(:group) { create(:group) }

      before do
        create_deploy_access_level(protected_environment, group: group)
      end

      it 'allows members of the group' do
        group.add_developer(user)

        expect(subject).to be_truthy
      end

      it 'rejects non-members of the group' do
        expect(subject).to be_falsy
      end
    end

    context 'when access has been granted to maintainers' do
      before do
        create_deploy_access_level(protected_environment, access_level: Gitlab::Access::MAINTAINER)
      end

      it 'allows maintainers' do
        project.add_maintainer(user)

        expect(subject).to be_truthy
      end

      it 'rejects developers' do
        project.add_developer(user)

        expect(subject).to be_falsy
      end
    end

    context 'when access has been granted to developers' do
      before do
        create_deploy_access_level(protected_environment, access_level: Gitlab::Access::DEVELOPER)
      end

      it 'allows maintainers' do
        project.add_maintainer(user)

        expect(subject).to be_truthy
      end

      it 'allows developers' do
        project.add_developer(user)

        expect(subject).to be_truthy
      end
    end
  end

  describe '#container_access_level' do
    subject { protected_environment.container_access_level(user) }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:developer) { create(:user) }

    before_all do
      project.add_maintainer(maintainer)
      project.add_developer(developer)
      group.add_maintainer(maintainer)
      group.add_developer(developer)
    end

    shared_examples_for 'correct access levels' do
      context 'for project maintainer' do
        let(:user) { maintainer }

        it { is_expected.to eq(Gitlab::Access::MAINTAINER) }
      end

      context 'for project developer' do
        let(:user) { developer }

        it { is_expected.to eq(Gitlab::Access::DEVELOPER) }
      end

      context 'when user is nil' do
        let(:user) { }

        it { is_expected.to eq(Gitlab::Access::NO_ACCESS) }
      end
    end

    context 'with project-level protected environment' do
      let!(:protected_environment) do
        create(:protected_environment, :project_level, project: project)
      end

      it_behaves_like 'correct access levels'
    end

    context 'with group-level protected environment' do
      let!(:protected_environment) do
        create(:protected_environment, :group_level, group: group)
      end

      it_behaves_like 'correct access levels'
    end
  end

  describe '.sorted_by_name' do
    subject(:protected_environments) { described_class.sorted_by_name }

    it "sorts protected environments by name" do
      %w(staging production development).each {|name| create(:protected_environment, name: name)}

      expect(protected_environments.map(&:name)).to eq %w(development production staging)
    end
  end

  describe '.with_environment_id' do
    subject(:protected_environments) { described_class.with_environment_id }

    it "sets corresponding environment id if there is environment matching by name and project" do
      project = create(:project)
      environment = create(:environment, project: project, name: 'production')

      production = create(:protected_environment, project: project, name: 'production')
      removed_environment = create(:protected_environment, project: project, name: 'removed environment')

      expect(protected_environments).to match_array [production, removed_environment]
      expect(protected_environments.find {|e| e.name == 'production'}.environment_id).to eq environment.id
      expect(protected_environments.find {|e| e.name == 'removed environment'}.environment_id).to be_nil
    end
  end

  describe '.deploy_access_levels_by_user' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:protected_environment) { create(:protected_environment, project: project, name: 'production') }
    let(:deploy_access_level_for_user) { create_deploy_access_level(protected_environment, user: user) }

    before do
      create_deploy_access_level(protected_environment, user: create(:user))
      create_deploy_access_level(protected_environment, group: create(:group))
    end

    it 'returns matching deploy access levels for the given user' do
      expect(described_class.deploy_access_levels_by_user(user))
        .to contain_exactly(deploy_access_level_for_user)
    end

    context 'when user is assigned to protected environment in the other project' do
      let(:other_project) { create(:project) }
      let(:other_protected_environment) { create(:protected_environment, project: other_project, name: 'production') }
      let(:other_deploy_access_level_for_user) { create_deploy_access_level(other_protected_environment, user: user) }

      it 'returns matching deploy access levels for the given user in the specific project' do
        expect(project.protected_environments.deploy_access_levels_by_user(user))
          .to contain_exactly(deploy_access_level_for_user)
        expect(other_project.protected_environments.deploy_access_levels_by_user(user))
          .to contain_exactly(other_deploy_access_level_for_user)
      end
    end
  end

  describe '.deploy_access_levels_by_group' do
    let(:group) { create(:group) }
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:protected_environment) { create(:protected_environment, project: project, name: 'production') }
    let(:deploy_access_level_for_group) { create_deploy_access_level(protected_environment, group: group) }

    it 'returns matching deploy access levels for the given group' do
      _deploy_access_level_for_different_group = create_deploy_access_level(protected_environment, group: create(:group))
      _deploy_access_level_for_user = create_deploy_access_level(protected_environment, user: create(:user))

      expect(described_class.deploy_access_levels_by_group(group))
        .to contain_exactly(deploy_access_level_for_group)
    end

    context 'when user is assigned to protected environment in the other project' do
      let(:other_project) { create(:project) }
      let(:other_protected_environment) { create(:protected_environment, project: other_project, name: 'production') }
      let(:other_deploy_access_level_for_group) { create_deploy_access_level(other_protected_environment, group: group) }

      it 'returns matching deploy access levels for the given group in the specific project' do
        expect(project.protected_environments.deploy_access_levels_by_group(group))
          .to contain_exactly(deploy_access_level_for_group)
        expect(other_project.protected_environments.deploy_access_levels_by_group(group))
          .to contain_exactly(other_deploy_access_level_for_group)
      end
    end
  end

  describe '.for_environment' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project, reload: true) { create(:project, group: group) }

    let!(:environment) { create(:environment, name: 'production', project: project) }
    let!(:protected_environment) { create(:protected_environment, name: 'production', project: project) }

    subject { described_class.for_environment(environment) }

    it { is_expected.to eq([protected_environment]) }

    it 'caches result', :request_store do
      described_class.for_environment(environment).to_a

      expect { described_class.for_environment(environment).to_a }
        .not_to exceed_query_limit(0)
    end

    context 'when environment is a different name' do
      let!(:environment) { create(:environment, name: 'staging', project: project) }

      it { is_expected.to be_empty }
    end

    context 'when environment exists in a different project' do
      let!(:environment) { create(:environment, name: 'production', project: create(:project)) }

      it { is_expected.to be_empty }
    end

    context 'when environment does not exist' do
      let!(:environment) { }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'with group-level protected environment' do
      let!(:group_protected_environment) { create(:protected_environment, :production, :group_level, group: group) }

      context 'with project-level production environment' do
        let!(:environment) { create(:environment, :production, project: project) }

        it 'has multiple protections' do
          is_expected.to contain_exactly(protected_environment, group_protected_environment)
        end

        context 'when project-level protection does not exist' do
          let!(:protected_environment) { }

          it 'has only group-level protection' do
            is_expected.to eq([group_protected_environment])
          end
        end
      end

      context 'with staging environment' do
        let(:environment) { create(:environment, :staging, project: project) }

        it 'does not have any protections' do
          is_expected.to be_empty
        end
      end
    end
  end

  def create_deploy_access_level(protected_environment, **opts)
    protected_environment.deploy_access_levels.create(**opts)
  end
end
