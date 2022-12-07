# frozen_string_literal: true

RSpec.shared_examples 'authorizable for protected environments' do |factory_name:|
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:protected_environment) { create(:protected_environment, project: project) }
  let_it_be(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:protected_environment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:access_level).in_array([Gitlab::Access::REPORTER, Gitlab::Access::DEVELOPER, Gitlab::Access::MAINTAINER]) }
  end

  describe '#check_access' do
    subject { authorizable.check_access(user) }

    context 'anonymous access' do
      let(:user) { nil }
      let(:authorizable) { create(factory_name, :maintainer_access, protected_environment: protected_environment) }

      it { is_expected.to be_falsy }
    end

    describe 'admin user has universal access' do
      let_it_be(:user) { create(:user, :admin) }

      context 'when admin user does have specific access' do
        let(:authorizable) { create(factory_name, protected_environment: protected_environment, user: user) }

        it { is_expected.to be_truthy }
      end

      context 'when admin user does not have specific access' do
        let(:authorizable) { create(factory_name, :maintainer_access, protected_environment: protected_environment) }

        it { is_expected.to be_truthy }
      end
    end

    describe 'non-admin user access' do
      context 'when specific access has been assigned to a user' do
        let(:authorizable) { create(factory_name, protected_environment: protected_environment, user: user) }

        it { is_expected.to be_truthy }
      end

      context 'when no permissions have been given to a user' do
        let(:authorizable) { create(factory_name, :maintainer_access, protected_environment: protected_environment) }

        it { is_expected.to be_falsy }
      end
    end

    describe 'group access' do
      let_it_be(:group) { create(:group, projects: [project]) }

      context 'when specific access has been assigned to a group' do
        let(:authorizable) { create(factory_name, protected_environment: protected_environment, group: group) }

        before do
          group.add_reporter(user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when no permissions have been given to a group' do
        let(:authorizable) { create(factory_name, :maintainer_access, protected_environment: protected_environment) }

        before do
          group.add_reporter(user)
        end

        it { is_expected.to be_falsy }
      end

      context 'when there is an inherited member of a group' do
        let_it_be(:parent_group) { create(:group) }
        let_it_be(:child_group) { create(:group, parent: parent_group, projects: [project]) }

        before do
          parent_group.add_reporter(user)
        end

        context 'when group inheritance type is direct' do
          let(:authorizable) { create(factory_name, protected_environment: protected_environment, group: child_group) }

          it { is_expected.to be_falsey }
        end

        context 'when group inheritance type is all inheritance' do
          let(:authorizable) { create(factory_name, protected_environment: protected_environment, group: child_group, group_inheritance_type: ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL]) }

          it { is_expected.to be_truthy }
        end
      end
    end

    describe 'access level' do
      context 'with a permitted access level' do
        let(:developer_access) { Gitlab::Access::DEVELOPER }
        let(:authorizable) { create(factory_name, protected_environment: protected_environment, access_level: developer_access) }

        context 'when user is project member above the permitted access level' do
          before do
            project.add_developer(user)
          end

          it { is_expected.to be_truthy }
        end

        context 'when user is project member below the permitted access level' do
          before do
            project.add_reporter(user)
          end

          it { is_expected.to be_falsy }
        end
      end

      context 'when the access level is not permitted' do
        let(:authorizable) { create(factory_name, protected_environment: protected_environment, access_level: Gitlab::Access::GUEST) }

        before do
          project.add_guest(user)
        end

        it 'does not save the record' do
          expect { authorizable }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end
  end

  describe '#humanize' do
    let_it_be(:protected_environment) { create(:protected_environment) }

    subject { authorizable.humanize }

    context 'when is related to a user' do
      let(:user) { create(:user) }
      let(:authorizable) { create(factory_name, protected_environment: protected_environment, user: user) }

      it { is_expected.to eq(user.name) }
    end

    context 'when is related to a group' do
      let(:group) { create(:group) }
      let(:authorizable) { create(factory_name, protected_environment: protected_environment, group: group) }

      it { is_expected.to eq(group.name) }
    end

    context 'when is set to have a role' do
      let(:authorizable) { create(factory_name, protected_environment: protected_environment, access_level: access_level) }

      context 'for developer access' do
        let(:access_level) { Gitlab::Access::DEVELOPER }

        it { is_expected.to eq('Developers + Maintainers') }
      end

      context 'for maintainer access' do
        let(:access_level) { Gitlab::Access::MAINTAINER }

        it { is_expected.to eq('Maintainers') }
      end
    end
  end

  describe '#type' do
    subject { authorizable.type }

    context 'with role type' do
      let(:authorizable) { create(factory_name, :maintainer_access, protected_environment: protected_environment) }

      it { is_expected.to eq(:role) }
    end

    context 'with user type' do
      let(:user) { create(:user) }
      let(:authorizable) { create(factory_name, protected_environment: protected_environment, user: user) }

      it { is_expected.to eq(:user) }
    end

    context 'with group type' do
      let(:group) { create(:group) }
      let(:authorizable) { create(factory_name, protected_environment: protected_environment, group: group) }

      it { is_expected.to eq(:group) }
    end
  end

  describe '#role?' do
    subject { authorizable.role? }

    context 'with role type' do
      let(:authorizable) { create(factory_name, :maintainer_access, protected_environment: protected_environment) }

      it { is_expected.to eq(true) }
    end

    context 'with user type' do
      let(:user) { create(:user) }
      let(:authorizable) { create(factory_name, protected_environment: protected_environment, user: user) }

      it { is_expected.to eq(false) }
    end
  end
end
