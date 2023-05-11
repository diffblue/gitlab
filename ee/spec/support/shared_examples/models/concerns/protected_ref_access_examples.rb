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
end
