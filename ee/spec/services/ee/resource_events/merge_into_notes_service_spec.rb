# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::MergeIntoNotesService, feature_category: :team_planning do
  def create_label_event(params)
    event_params = { action: :add, label: label, issue: resource,
                     user: user }

    create(:resource_label_event, event_params.merge(params))
  end

  def create_weight_event(params, weight = resource.weight)
    event_params = { issue: resource, user: user }

    create(:resource_weight_event, event_params.merge(params))
  end

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:resource) { create(:issue, project: project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }
  let_it_be(:scoped_label_group1_1) { create(:label, project: project, title: 'key::value') }
  let_it_be(:scoped_label_group1_2) { create(:label, project: project, title: 'key::value2') }
  let_it_be(:scoped_label_group2_1) { create(:label, project: project, title: 'key2::value') }
  let_it_be(:scoped_label_group2_2) { create(:label, project: project, title: 'key2::value2') }
  let_it_be(:scoped_label_group3_1) { create(:label, project: project, title: 'key3::value') }

  let(:time) { Time.current }

  describe '#execute' do
    it 'squashes events with same time and author into single note but scoped labels are separated' do
      user2 = create(:user)

      create_label_event(created_at: time)
      create_label_event(created_at: time, label: label2, action: :remove)
      create_label_event(created_at: time, label: scoped_label_group1_1, action: :remove)
      create_label_event(created_at: time, label: scoped_label_group1_2, action: :add)
      create_label_event(created_at: time, label: scoped_label_group2_2, action: :remove)
      create_label_event(created_at: time, label: scoped_label_group2_1, action: :add)
      create_label_event(created_at: time, label: scoped_label_group3_1, action: :add)
      create_label_event(created_at: time, user: user2)
      create_label_event(created_at: 1.day.ago, label: label2)

      notes = described_class.new(resource, user).execute

      added_scoped_labels_refs = [scoped_label_group1_2, scoped_label_group2_1, scoped_label_group3_1].map(&:to_reference).sort.join(' ')
      removed_scoped_labels_refs = [scoped_label_group1_1, scoped_label_group2_2].map(&:to_reference).sort.join(' ')

      expected = [
        "added #{added_scoped_labels_refs} scoped labels " \
          "and automatically removed #{removed_scoped_labels_refs} labels",
        "added #{label.to_reference} label and removed #{label2.to_reference} label",
        "added #{label.to_reference} label",
        "added #{label2.to_reference} label"
      ]

      expect(notes.count).to eq(4)
      expect(notes.map(&:note)).to match_array(expected)
    end

    context 'scoped labels' do
      context 'when all labels are automatically removed' do
        it 'adds "automatically removed" message' do
          create_label_event(created_at: time, label: scoped_label_group1_1, action: :add)
          create_label_event(created_at: time, label: scoped_label_group1_2, action: :remove)
          create_label_event(created_at: time, label: scoped_label_group2_1, action: :add)
          create_label_event(created_at: time, label: scoped_label_group2_2, action: :remove)

          note = described_class.new(resource, user).execute.first.note

          added_scoped_labels_refs = [scoped_label_group1_1, scoped_label_group2_1].map(&:to_reference).sort.join(' ')
          removed_scoped_labels_refs = [scoped_label_group1_2, scoped_label_group2_2].map(&:to_reference).sort.join(' ')

          expect(note).to eq("added #{added_scoped_labels_refs} scoped labels and automatically removed #{removed_scoped_labels_refs} labels")
        end
      end

      context 'when any of the labels is manually removed' do
        it 'adds "removed" message' do
          create_label_event(created_at: time, label: scoped_label_group1_1, action: :add)
          create_label_event(created_at: time, label: scoped_label_group1_2, action: :remove)
          create_label_event(created_at: time, label: scoped_label_group2_1, action: :remove)

          note = described_class.new(resource, user).execute.first.note

          added_scoped_labels_refs = scoped_label_group1_1.to_reference
          removed_scoped_labels_refs = [scoped_label_group1_2, scoped_label_group2_1].map(&:to_reference).sort.join(' ')

          expect(note).to eq("added #{added_scoped_labels_refs} scoped label and removed #{removed_scoped_labels_refs} labels")
        end
      end
    end

    context 'with weight events' do
      it 'includes the expected notes' do
        create_weight_event(created_at: time, weight: 3)
        create_weight_event(created_at: time, weight: 1)
        create_weight_event(created_at: time, weight: 5)

        notes = described_class.new(resource, user).execute

        expect(notes.size).to eq(3)

        expect(notes[0].note).to eq('changed weight to 3')
        expect(notes[1].note).to eq('changed weight to 1')
        expect(notes[2].note).to eq('changed weight to 5')
      end
    end
  end
end
