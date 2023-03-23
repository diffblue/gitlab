# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::TreeSaver do
  describe 'saves the group tree into a json object' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:label) { create(:group_label) }
    let_it_be(:parent_epic) { create(:epic, group: group) }
    let_it_be(:epic, reload: true) { create(:epic, group: group, parent: parent_epic) }
    let_it_be(:epic_event) { create(:event, :created, target: epic, group: group, author: user) }
    let_it_be(:epic_label_link) { create(:label_link, label: label, target: epic) }
    let_it_be(:epic_push_event) { create(:event, :pushed, target: epic, group: group, author: user) }
    let_it_be(:milestone) { create(:milestone, group: group) }
    let_it_be(:board) { create(:board, group: group, assignee: user, labels: [label]) }
    let_it_be(:note) { create(:note, noteable: epic) }
    let_it_be(:note_event) { create(:event, :created, target: note, author: user) }
    let_it_be(:epic_emoji) { create(:award_emoji, awardable: epic) }
    let_it_be(:epic_note_emoji) { create(:award_emoji, awardable: note) }

    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:export_path) { "#{Dir.tmpdir}/group_tree_saver_spec_ee" }

    subject(:group_tree_saver) { described_class.new(group: group, current_user: user, shared: shared) }

    before_all do
      group.add_maintainer(user)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves successfully' do
      expect_successful_save(group_tree_saver)
    end

    context 'epics relation' do
      before do
        stub_licensed_features(epics: true)
      end

      let(:epic_json) do
        read_association(group, 'epics').find do |attrs|
          attrs['id'] == epic.id
        end
      end

      it 'saves top level epics' do
        expect_successful_save(group_tree_saver)

        expect(read_association(group, "epics").size).to eq(2)
      end

      it 'saves parent of epic' do
        expect_successful_save(group_tree_saver)

        parent = epic_json['parent']

        expect(parent).not_to be_empty
        expect(parent['id']).to eq(parent_epic.id)
      end

      it 'saves epic notes' do
        expect_successful_save(group_tree_saver)

        notes = epic_json['notes']

        expect(notes).not_to be_empty
        expect(notes.first['note']).to eq(note.note)
        expect(notes.first['noteable_id']).to eq(epic.id)
      end

      it 'saves epic events' do
        expect_successful_save(group_tree_saver)

        events = epic_json['events']
        expect(events).not_to be_empty

        event_actions = events.map { |event| event['action'] }
        expect(event_actions).to contain_exactly(epic_event.action, epic_push_event.action)
      end

      it "saves epic's note events" do
        expect_successful_save(group_tree_saver)

        notes = epic_json['notes']
        expect(notes.first['events'].first['action']).to eq(note_event.action)
      end

      it "saves epic's award emojis" do
        expect_successful_save(group_tree_saver)

        award_emoji = epic_json['award_emoji'].first
        expect(award_emoji['name']).to eq(epic_emoji.name)
      end

      it "saves epic's note award emojis" do
        expect_successful_save(group_tree_saver)

        award_emoji = epic_json['notes'].first['award_emoji'].first
        expect(award_emoji['name']).to eq(epic_note_emoji.name)
      end

      it 'saves epic labels' do
        expect_successful_save(group_tree_saver)

        epic_label = epic_json['label_links'].first['label']
        expect(epic_label['title']).to eq(label.title)
        expect(epic_label['description']).to eq(label.description)
        expect(epic_label['color']).to be_color(label.color)
      end

      it 'saves resource state events' do
        epic.resource_state_events.create!(user: user, state: 'closed')

        expect_successful_save(group_tree_saver)

        event = epic_json['resource_state_events'].first

        expect(event['state']).to eq('closed')
      end

      context 'with inaccessible resources' do
        let_it_be(:external_parent) { create(:epic, group: create(:group, :private)) }

        it 'filters out inaccessible epic parent' do
          epic.update!(parent: external_parent)

          expect_successful_save(group_tree_saver)
          expect(epic_json['parent']).to be_nil
        end

        it 'filters out inaccessible epic notes' do
          note_text = "added epic #{external_parent.to_reference(full: true)} as parent epic"
          note2 = create(:system_note, noteable: epic, note: note_text)
          create(:system_note_metadata, note: note2, action: 'relate_epic')

          expect_successful_save(group_tree_saver)
          expect(epic_json['notes'].count).to eq(1)
          expect(epic_json['notes'].first['note']).to eq(note.note)
        end
      end
    end

    context 'boards relation' do
      before do
        stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)

        create(:list, board: board, user: user, list_type: List.list_types[:assignee], position: 0)
        create(:list, board: board, milestone: milestone, list_type: List.list_types[:milestone], position: 1)

        expect_successful_save(group_tree_saver)
      end

      it 'saves top level boards' do
        expect(read_association(group, 'boards').size).to eq(1)
      end

      it 'saves board assignee' do
        expect(read_association(group, 'boards').first['board_assignee']['assignee_id']).to eq(user.id)
      end

      it 'saves board labels' do
        labels = read_association(group, 'boards').first['labels']

        expect(labels).not_to be_empty
        expect(labels.first['title']).to eq(label.title)
      end

      it 'saves board lists' do
        lists = read_association(group, 'boards').first['lists']

        expect(lists).not_to be_empty

        milestone_list = lists.find { |list| list['list_type'] == 'milestone' }
        assignee_list = lists.find { |list| list['list_type'] == 'assignee' }

        expect(milestone_list['milestone_id']).to eq(milestone.id)
        expect(assignee_list['user_id']).to eq(user.id)
      end
    end

    it 'saves the milestone data when there are boards with predefined milestones' do
      milestone = Milestone::Upcoming
      board_with_milestone = create(:board, group: group, milestone_id: milestone.id)

      expect_successful_save(group_tree_saver)

      board_data = read_association(group, 'boards').find { |board| board['id'] == board_with_milestone.id }

      expect(board_data).to include(
        'milestone_id' => milestone.id,
        'milestone' => {
          'id' => milestone.id,
          'name' => milestone.name,
          'title' => milestone.title
        }
      )
    end

    it 'saves the milestone data when there are boards with persisted milestones' do
      milestone = create(:milestone)
      board_with_milestone = create(:board, group: group, milestone_id: milestone.id)

      expect_successful_save(group_tree_saver)

      board_data = read_association(group, 'boards').find { |board| board['id'] == board_with_milestone.id }

      expect(board_data).to include(
        'milestone_id' => milestone.id,
        'milestone' => a_hash_including(
          'id' => milestone.id,
          'title' => milestone.title
        )
      )
    end

    context 'iteration cadences relation' do
      it 'saves iteration cadences with iterations', :aggregate_failures do
        cadence = create(:iterations_cadence, group: group, description: 'description')
        iteration = create(:iteration, iterations_cadence: cadence)

        expect_successful_save(group_tree_saver)

        cadence_data = read_association(group, 'iterations_cadences').first
        iteration_data = cadence_data['iterations'].first

        expect(cadence_data).to include('title' => cadence.title, 'description' => cadence.description)
        expect(iteration_data).to include('iid' => iteration.iid)
      end
    end
  end

  def exported_path_for(file)
    File.join(group_tree_saver.full_path, 'groups', file)
  end

  def read_association(group, association)
    path = exported_path_for(File.join(group.id.to_s, "#{association}.ndjson"))

    File.foreach(path).map { |line| Gitlab::Json.parse(line) }
  end

  def expect_successful_save(group_tree_saver)
    expect(group_tree_saver.save).to be true
    expect(group_tree_saver.shared.errors).to be_empty
  end
end
