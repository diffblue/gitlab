# frozen_string_literal: true

RSpec.shared_examples 'search confidential notes shared examples' do
  context 'notes confidentiality', :elastic, :sidekiq_inline do
    let_it_be(:user) { create(:user) }

    let(:commit_id) { noteable.is_a?(Commit) ? noteable.id : nil }
    let(:noteable_id) { noteable.is_a?(Issuable) ? noteable.id : nil }
    let!(:not_confidential_note) { create(:note, confidential: false, noteable_id: noteable_id, commit_id: commit_id, noteable_type: noteable.class.name, project: noteable.project, note: 'note 1') }
    let!(:nil_confidential_note) { create(:note, noteable_id: noteable_id, commit_id: commit_id, noteable_type: noteable.class.name, project: noteable.project, note: 'note 2') }
    let!(:confidential_note) { create(:note, confidential: true, noteable_id: noteable_id, commit_id: commit_id, noteable_type: noteable.class.name, project: noteable.project, note: 'note 2') }

    before do
      ensure_elasticsearch_index!
    end

    context 'for anonymous user' do
      it 'filters confidential notes' do
        expect_search_results(nil, 'notes', expected_objects: []) do |user|
          described_class.new(nil, search: 'note').execute
        end
      end
    end

    context 'when user cannot read confidential notes' do
      it 'filters confidential notes' do
        noteable.project.add_guest(user)

        expect_search_results(user, 'notes', expected_objects: [not_confidential_note, nil_confidential_note]) do |user|
          described_class.new(user, search: 'note').execute
        end
      end
    end

    context 'when user can read confidential notes' do
      it 'does not filter confidential notes' do
        noteable.project.add_reporter(user)

        expect_search_results(user, 'notes', expected_objects: [not_confidential_note, nil_confidential_note, confidential_note]) do |user|
          described_class.new(user, search: 'note').execute
        end
      end
    end

    # For now only issues and epics can be confidential and have confidential notes,
    # these specs are here to make sure not confidential notes on confidential issues
    # does not get leaked when mixed with other issuable notes.
    context 'with additional notes on a confidential issue' do
      let!(:not_confidential_note_on_confidential_issue) { create(:note, project: noteable.project, noteable: confidential_issue, note: 'note 4') }
      let!(:confidential_note_on_confidential_issue) { create(:note, confidential: true, project: noteable.project, noteable: confidential_issue, note: 'note 5') }

      context 'when user cannot read confidential' do
        let(:confidential_issue) { create :issue, confidential: true, project: noteable.project }

        it 'filters all notes from confidential issue' do
          confidential_issue.project.add_guest(user)

          ensure_elasticsearch_index!

          expect_search_results(user, 'notes', expected_objects: [not_confidential_note, nil_confidential_note]) do |user|
            described_class.new(user, search: 'note').execute
          end
        end
      end

      context 'when user can read confidential' do
        context 'when user is project reporter' do
          let(:confidential_issue) { create :issue, confidential: true, project: noteable.project }

          it 'does not filter confidential issue notes' do
            confidential_issue.project.add_reporter(user)

            ensure_elasticsearch_index!

            expected_objects = [
              not_confidential_note, nil_confidential_note, confidential_note,
              not_confidential_note_on_confidential_issue, confidential_note_on_confidential_issue
            ]
            expect_search_results(user, 'notes', expected_objects: expected_objects) do |user|
              described_class.new(user, search: 'note').execute
            end
          end
        end

        context 'when user is a participant' do
          let(:expected_objects) do
            [
              not_confidential_note, nil_confidential_note,
              not_confidential_note_on_confidential_issue
            ]
          end

          context 'as issue author' do
            let(:confidential_issue) { create :issue, confidential: true, project: noteable.project, author: user }

            it 'filters confidential issue notes' do
              ensure_elasticsearch_index!

              expect_search_results(user, 'notes', expected_objects: expected_objects) do |user|
                described_class.new(user, search: 'note').execute
              end
            end
          end

          context 'as issue assignee' do
            let(:confidential_issue) { create :issue, confidential: true, project: noteable.project, assignees: [user] }

            it 'filters confidential issue notes' do
              ensure_elasticsearch_index!

              expect_search_results(user, 'notes', expected_objects: expected_objects) do |user|
                described_class.new(user, search: 'note').execute
              end
            end
          end
        end
      end
    end
  end
end
