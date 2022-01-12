# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallParticipant do
  let_it_be(:rotation) { create(:incident_management_oncall_rotation) }
  let_it_be(:user) { create(:user) }
  let_it_be(:participant) { create(:incident_management_oncall_participant, rotation: rotation) }

  subject { build(:incident_management_oncall_participant, rotation: rotation, user: user) }

  it { is_expected.to be_valid }

  before_all do
    rotation.project.add_developer(user)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:rotation) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:shifts) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:rotation) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:color_weight) }
    it { is_expected.to validate_presence_of(:color_palette) }

    context 'when the participant already exists in the rotation' do
      before do
        create(:incident_management_oncall_participant, rotation: rotation, user: user)
      end

      it 'has validation errors' do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages.to_sentence).to eq('User has already been taken')
      end
    end
  end

  describe 'scopes' do
    let_it_be(:removed_participant) { create(:incident_management_oncall_participant, :removed, rotation: rotation) }

    describe '.not_removed' do
      subject { described_class.not_removed }

      it { is_expected.to contain_exactly(participant) }
    end

    describe '.removed' do
      subject { described_class.removed }

      it { is_expected.to contain_exactly(removed_participant) }
    end

    describe '.for_user' do
      subject { described_class.for_user(participant.user) }

      it { is_expected.to contain_exactly(participant) }
    end
  end

  private

  def remove_user_from_project(user, project)
    Members::DestroyService.new(user).execute(project.member(user))
  end
end
