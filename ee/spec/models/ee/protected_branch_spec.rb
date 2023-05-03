# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch, feature_category: :source_code_management do
  subject { create(:protected_branch) }

  let(:project) { subject.project }
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to have_many(:required_code_owners_sections).class_name('ProtectedBranch::RequiredCodeOwnersSection') }
    it { is_expected.to have_and_belong_to_many(:approval_project_rules) }

    it do
      is_expected
        .to have_and_belong_to_many(:external_status_checks)
        .class_name('::MergeRequests::ExternalStatusCheck')
    end
  end

  shared_examples 'uniqueness validation' do |access_level_class|
    let(:factory_name) { access_level_class.to_s.underscore.sub('/', '_').to_sym }
    let(:association_name) { access_level_class.to_s.underscore.sub('protected_branch/', '').pluralize.to_sym }

    human_association_name = access_level_class.to_s.underscore.humanize.sub('Protected branch/', '')

    context "while checking uniqueness of a role-based #{human_association_name}" do
      it "allows a single #{human_association_name} for a role (per protected branch)" do
        first_protected_branch = create(:protected_branch, default_access_level: false)
        second_protected_branch = create(:protected_branch, default_access_level: false)

        first_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MAINTAINER)
        second_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MAINTAINER)

        expect(first_protected_branch).to be_valid
        expect(second_protected_branch).to be_valid

        first_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MAINTAINER)
        expect(first_protected_branch).to be_invalid
        expect(first_protected_branch.errors.full_messages.first).to match("access level has already been taken")
      end

      it "does not count a user-based #{human_association_name} with an `access_level` set" do
        protected_branch = create(:protected_branch, default_access_level: false)
        protected_branch.project.add_developer(user)

        protected_branch.send(association_name) << build(factory_name, user: user, access_level: Gitlab::Access::MAINTAINER)
        protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MAINTAINER)

        expect(protected_branch).to be_valid
      end

      it "does not count a group-based #{human_association_name} with an `access_level` set" do
        group = create(:group)
        protected_branch = create(:protected_branch, default_access_level: false)
        protected_branch.project.project_group_links.create!(group: group)

        protected_branch.send(association_name) << build(factory_name, group: group, access_level: Gitlab::Access::MAINTAINER)
        protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MAINTAINER)

        expect(protected_branch).to be_valid
      end
    end

    context "while checking uniqueness of a user-based #{human_association_name}" do
      it "allows a single #{human_association_name} for a user (per protected branch)" do
        first_protected_branch = create(:protected_branch, default_access_level: false)
        second_protected_branch = create(:protected_branch, default_access_level: false)

        first_protected_branch.project.add_developer(user)
        second_protected_branch.project.add_developer(user)

        first_protected_branch.send(association_name) << build(factory_name, user: user)
        second_protected_branch.send(association_name) << build(factory_name, user: user)

        expect(first_protected_branch).to be_valid
        expect(second_protected_branch).to be_valid

        first_protected_branch.send(association_name) << build(factory_name, user: user)
        expect(first_protected_branch).to be_invalid
        expect(first_protected_branch.errors.full_messages.first).to match("user has already been taken")
      end

      it "ignores the `access_level` while validating a user-based #{human_association_name}" do
        protected_branch = create(:protected_branch, default_access_level: false)
        protected_branch.project.add_developer(user)

        protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MAINTAINER)
        protected_branch.send(association_name) << build(factory_name, user: user, access_level: Gitlab::Access::MAINTAINER)

        expect(protected_branch).to be_valid
      end
    end

    context "while checking uniqueness of a group-based #{human_association_name}" do
      let(:group) { create(:group) }

      it "allows a single #{human_association_name} for a group (per protected branch)" do
        first_protected_branch = create(:protected_branch, default_access_level: false)
        second_protected_branch = create(:protected_branch, default_access_level: false)

        first_protected_branch.project.project_group_links.create!(group: group)
        second_protected_branch.project.project_group_links.create!(group: group)

        first_protected_branch.send(association_name) << build(factory_name, group: group)
        second_protected_branch.send(association_name) << build(factory_name, group: group)

        expect(first_protected_branch).to be_valid
        expect(second_protected_branch).to be_valid

        first_protected_branch.send(association_name) << build(factory_name, group: group)
        expect(first_protected_branch).to be_invalid
        expect(first_protected_branch.errors.full_messages.first).to match("group has already been taken")
      end

      it "ignores the `access_level` while validating a group-based #{human_association_name}" do
        protected_branch = create(:protected_branch, default_access_level: false)
        protected_branch.project.project_group_links.create!(group: group)

        protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MAINTAINER)
        protected_branch.send(association_name) << build(factory_name, group: group, access_level: Gitlab::Access::MAINTAINER)

        expect(protected_branch).to be_valid
      end
    end
  end

  it_behaves_like 'uniqueness validation', ProtectedBranch::MergeAccessLevel
  it_behaves_like 'uniqueness validation', ProtectedBranch::PushAccessLevel

  describe "#code_owner_approval_required" do
    context "when the attr code_owner_approval_required is true" do
      let(:subject_branch) { create(:protected_branch, code_owner_approval_required: true) }

      it "returns true" do
        expect(subject_branch.project)
          .to receive(:code_owner_approval_required_available?).once.and_return(true)
        expect(subject_branch.code_owner_approval_required).to be_truthy
      end

      it "returns false when the project doesn't require approvals" do
        expect(subject_branch.project)
          .to receive(:code_owner_approval_required_available?).once.and_return(false)
        expect(subject_branch.code_owner_approval_required).to be_falsy
      end
    end

    context "when the attr code_owner_approval_required is false" do
      let(:subject_branch) { create(:protected_branch, code_owner_approval_required: false) }

      it "returns false" do
        expect(subject_branch.code_owner_approval_required).to be_falsy
      end
    end
  end

  describe '#can_unprotect?' do
    let(:admin) { create(:user, :admin) }
    let(:maintainer) do
      create(:user).tap { |user| project.add_maintainer(user) }
    end

    context 'without unprotect_access_levels' do
      it "doesn't add any additional restriction" do
        expect(subject.can_unprotect?(user)).to eq true
      end
    end

    context 'with access level set to MAINTAINER' do
      before do
        subject.unprotect_access_levels.create!(access_level: Gitlab::Access::MAINTAINER)
      end

      it 'prevents access to users' do
        expect(subject.can_unprotect?(user)).to eq(false)
      end

      it 'grants access to maintainers' do
        expect(subject.can_unprotect?(maintainer)).to eq(true)
      end

      it 'prevents access to admins' do
        expect(subject.can_unprotect?(admin)).to eq(false)
      end
    end

    context 'with access level set to ADMIN' do
      before do
        subject.unprotect_access_levels.create!(access_level: Gitlab::Access::ADMIN)
      end

      it 'prevents access to maintainers' do
        expect(subject.can_unprotect?(maintainer)).to eq(false)
      end

      it 'grants access to admins' do
        expect(subject.can_unprotect?(admin)).to eq(true)
      end
    end

    context 'multiple access levels' do
      before do
        project.add_developer(user)
        subject.unprotect_access_levels.create!(user: maintainer)
        subject.unprotect_access_levels.create!(user: user)
      end

      it 'grants access if any grant access' do
        expect(subject.can_unprotect?(user)).to eq true
      end
    end
  end

  describe '.branch_requires_code_owner_approval?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let(:branch_name) { "BRANCH_NAME" }

    before do
      allow(project).to receive(:code_owner_approval_required_available?).and_return(true)
    end

    subject { described_class.branch_requires_code_owner_approval?(project, branch_name) }

    context 'when there are no match branches' do
      it 'return false' do
        expect(subject).to eq(false)
      end
    end

    context 'when `code_owner_approval_required_available?` of project is false' do
      before do
        allow(project).to receive(:code_owner_approval_required_available?).and_return(false)
      end

      it 'return false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there are matched branches' do
      using RSpec::Parameterized::TableSyntax

      where(:feature_available, :object, :code_owner_approval_required, :result) do
        true   | ref(:project)         | false        | false
        true   | ref(:project)         | true         | true
        false  | ref(:project)         | true         | true
        true   | ref(:group)           | false        | false
        true   | ref(:group)           | true         | true
        false  | ref(:group)           | true         | false
      end

      with_them do
        before do
          stub_feature_flags(group_protected_branches: feature_available)
          stub_feature_flags(allow_protected_branches_for_group: feature_available)

          params = object.is_a?(Project) ? { project: object } : { project: nil, group: object }

          create(:protected_branch, name: branch_name, code_owner_approval_required: code_owner_approval_required, **params)
        end

        it { expect(subject).to eq(result) }
      end
    end
  end

  describe '#inherited?' do
    context 'when the `namespace_id` is nil' do
      before do
        subject.assign_attributes(namespace_id: nil)
      end

      it { is_expected.not_to be_inherited }
    end

    context 'when the `namespace_id` is present' do
      before do
        subject.assign_attributes(namespace_id: 123)
      end

      it { is_expected.to be_inherited }
    end
  end
end
