# frozen_string_literal: true

RSpec.shared_examples 'ee protected ref access' do |association|
  let_it_be(:project) { create(:project) }
  let_it_be(:protected_ref) { create(association, project: project) } # rubocop:disable Rails/SaveBang

  describe '#check_access' do
    let_it_be(:current_user) { create(:user) }

    let(:access_level) { nil }
    let(:user) { nil }
    let(:group) { nil }

    before_all do
      project.add_maintainer(current_user)
    end

    subject do
      described_class.new(
        association => protected_ref,
        user: user,
        group: group,
        access_level: access_level
      )
    end

    context 'when user is assigned' do
      context 'when current_user is the user' do
        let(:user) { current_user }

        it { expect(subject.check_access(current_user)).to eq(true) }
      end

      context 'when current_user is another user' do
        let(:user) { create(:user) }

        it { expect(subject.check_access(current_user)).to eq(false) }
      end
    end

    context 'when group is assigned' do
      let(:group) { create(:group) }

      context 'when current_user is in the group' do
        before do
          group.add_developer(current_user)
        end

        it { expect(subject.check_access(current_user)).to eq(true) }
      end

      context 'when current_user is not in the group' do
        it { expect(subject.check_access(current_user)).to eq(false) }
      end
    end
  end

  describe 'group membership validation' do
    subject do
      described_class.new(
        association => protected_ref,
        user: user,
        group: group,
        access_level: access_level
      )
    end

    let(:protected_ref) { create(association, project: project) }
    let(:user) { create :user }
    let(:access_level) { nil }
    let(:project) { create :project, :empty_repo }
    let(:group) { nil }

    context 'when project is not linked to group' do
      let(:group) { create :group }

      it 'adds an error' do
        subject.valid?
        expect(subject.errors.messages[:group]).to include('does not have access to the project')
      end
    end

    context 'when the project belongs to a group' do
      let(:project) { create :project, :empty_repo, namespace: create(:group) }
      let(:group) { project.group }

      it 'does not add an error' do
        subject.valid?
        expect(subject.errors.messages[:group]).to be_empty
      end
    end

    context 'when project is in a subgroup' do
      let(:project) { create :project, :empty_repo, :in_subgroup }
      let(:group) { project.group.parent }

      it 'does not add an error' do
        subject.valid?
        expect(subject.errors.messages[:group]).to be_empty
      end
    end

    context 'when group is invited to the project' do
      let(:project) { create :project }
      let(:group) { create :group }

      before do
        project.invited_groups << group
      end

      it 'does not add an error' do
        subject.valid?
        expect(subject.errors.messages[:group]).to be_empty
      end
    end

    context 'when importing' do
      before do
        subject.importing = true
      end

      it 'does not validate group membership' do
        expect(subject).not_to receive(:validate_group_membership)
        subject.valid?
      end
    end

    context 'when type is role' do
      let(:group) { nil }
      let(:user) { nil }

      it 'does not validate group membership' do
        expect(subject).not_to receive(:validate_group_membership)
        subject.valid?
      end
    end
  end
end
