# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::EpicLinks::DestroyService, feature_category: :portfolio_management do
  describe '#execute' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let(:epic) { create(:epic, group: group) }
    let!(:child_epic) { create(:epic, parent: epic, group: group) }

    shared_examples 'system notes created' do
      it 'creates system notes' do
        expect { subject }.to change { Note.system.count }.from(0).to(2)
      end
    end

    shared_examples 'returns success' do
      it 'removes epic relationship' do
        expect { subject }.to change { epic.children.count }.by(-1)

        expect(epic.reload.children).not_to include(child_epic)
      end

      it 'returns success status' do
        expect(subject).to eq(message: 'Relation was removed', status: :success)
      end
    end

    shared_examples 'returns not found error' do
      it 'returns an error' do
        expect(subject).to eq(message: 'No Epic found for given params', status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { epic.children.count }
      end

      it 'does not create system notes' do
        expect { subject }.not_to change { Note.system.count }
      end
    end

    def remove_epic_relation(child_epic)
      described_class.new(child_epic, user).execute
    end

    context 'when epics feature is disabled' do
      before do
        stub_licensed_features(epics: false)
      end

      subject { remove_epic_relation(child_epic) }

      include_examples 'returns not found error'
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when the user has no permissions to remove epic relation' do
        subject { remove_epic_relation(child_epic) }

        include_examples 'returns not found error'
      end

      context 'when user has permissions to remove epic relation' do
        before do
          group.add_guest(user)
        end

        context 'when the child epic is nil' do
          subject { remove_epic_relation(nil) }

          include_examples 'returns not found error'
        end

        context 'when a correct reference is given' do
          subject { remove_epic_relation(child_epic) }

          include_examples 'returns success'
          include_examples 'system notes created'
        end

        context 'when epic has no parent' do
          subject { remove_epic_relation(epic) }

          include_examples 'returns not found error'
        end
      end
    end
  end
end
