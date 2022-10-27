# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotePolicy do
  describe '#rules' do
    let(:reporter) { create(:user) }
    let(:developer) { create(:user) }
    let(:maintainer) { create(:user) }
    let(:guest) { create(:user) }
    let(:non_member) { create(:user) }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }

    let(:group) { create(:group) }
    let(:epic) { create(:epic, group: group, author: author) }
    let(:note) { create(:note, :on_epic, noteable: epic) }

    before do
      stub_licensed_features(epics: true)

      group.add_reporter(reporter)
      group.add_developer(developer)
      group.add_maintainer(maintainer)
      group.add_guest(guest)
    end

    def permissions(user)
      described_class.new(user, note)
    end

    shared_examples_for 'private notes' do
      it 'does not allow non members to read notes' do
        expect(permissions(non_member)).to be_disallowed(:read_note, :admin_note)
      end

      it 'allows reporter to read notes' do
        expect(permissions(reporter)).to be_allowed(:read_note)
        expect(permissions(reporter)).to be_disallowed(:admin_note)
      end

      it 'allows developer to read notes' do
        expect(permissions(developer)).to be_allowed(:read_note)
        expect(permissions(developer)).to be_disallowed(:admin_note)
      end

      it 'allows maintainers to read notes and admin them' do
        expect(permissions(maintainer)).to be_allowed(:read_note, :admin_note)
      end
    end

    context 'for epics in a public group' do
      context 'with non-confidential notes' do
        let(:note) { create(:note, :on_epic, noteable: epic) }

        it 'allows non members to read notes' do
          expect(permissions(non_member)).to be_allowed(:read_note)
          expect(permissions(non_member)).to be_disallowed(:admin_note)
        end

        it 'allows guests only to read notes' do
          expect(permissions(guest)).to be_allowed(:read_note)
          expect(permissions(guest)).to be_disallowed(:admin_note)
        end

        it 'allows reporters only to read notes' do
          expect(permissions(reporter)).to be_allowed(:read_note)
          expect(permissions(reporter)).to be_disallowed(:admin_note)
        end

        it 'allows developers only to read notes' do
          expect(permissions(developer)).to be_allowed(:read_note)
          expect(permissions(developer)).to be_disallowed(:admin_note)
        end

        it 'allows maintainers to read notes and admin them' do
          expect(permissions(maintainer)).to be_allowed(:read_note, :admin_note)
        end

        it 'allows noteable author to read notes' do
          expect(permissions(author)).to be_allowed(:read_note)
          expect(permissions(author)).to be_disallowed(:admin_note)
        end
      end

      context 'with confidential notes' do
        let(:note) { create(:note, :confidential, :on_epic, noteable: epic) }

        it_behaves_like 'private notes'

        it 'does not allow guests to read confidential notes and replies' do
          expect(permissions(guest)).to be_disallowed(:read_note, :admin_note)
        end

        it 'does not allow noteable author to read note' do
          expect(permissions(author)).to be_disallowed(:read_note)
          expect(permissions(author)).to be_disallowed(:admin_note)
        end
      end
    end

    context 'for epics in a private group' do
      before do
        group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'private notes'

      it 'does not allow guests to read notes' do
        expect(permissions(guest)).to be_allowed(:read_note)
        expect(permissions(guest)).to be_disallowed(:admin_note)
      end
    end
  end
end
