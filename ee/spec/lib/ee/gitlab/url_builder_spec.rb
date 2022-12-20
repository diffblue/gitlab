# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UrlBuilder do
  subject { described_class }

  describe '.build' do
    using RSpec::Parameterized::TableSyntax

    where(:factory, :path_generator) do
      :epic                  | ->(epic)          { "/groups/#{epic.group.full_path}/-/epics/#{epic.iid}" }
      :epic_board            | ->(epic_board)    { "/groups/#{epic_board.group.full_path}/-/epic_boards/#{epic_board.id}" }
      :vulnerability         | ->(vulnerability) { "/#{vulnerability.project.full_path}/-/security/vulnerabilities/#{vulnerability.id}" }

      :note_on_epic          | ->(note)          { "/groups/#{note.noteable.group.full_path}/-/epics/#{note.noteable.iid}#note_#{note.id}" }
      :note_on_vulnerability | ->(note)          { "/#{note.project.full_path}/-/security/vulnerabilities/#{note.noteable.id}#note_#{note.id}" }

      :group_wiki            | ->(wiki)          { "/groups/#{wiki.container.full_path}/-/wikis/home" }

      [:issue, :objective]   | ->(issue)         { "/#{issue.project.full_path}/-/work_items/#{issue.iid}?iid_path=true" }
      [:issue, :key_result]  | ->(issue)         { "/#{issue.project.full_path}/-/work_items/#{issue.iid}?iid_path=true" }
    end

    with_them do
      let(:object) { build_stubbed(*Array(factory)) }
      let(:path) { path_generator.call(object) }

      it 'returns the full URL' do
        expect(subject.build(object)).to eq("#{Settings.gitlab['url']}#{path}")
      end

      it 'returns only the path if only_path is set' do
        expect(subject.build(object, only_path: true)).to eq(path)
      end
    end

    context 'when use_iid_in_work_items_path feature flag is disabled' do
      before do
        stub_feature_flags(use_iid_in_work_items_path: false)
      end

      context 'when a objective issue is passed' do
        it 'returns a path using the work item\'s ID and no query params' do
          objective = create(:issue, :objective)

          expect(subject.build(objective, only_path: true)).to eq("/#{objective.project.full_path}/-/work_items/#{objective.id}")
        end
      end

      context 'when a key_result issue is passed' do
        it 'returns a path using the work item\'s ID and no query params' do
          key_result = create(:issue, :key_result)

          expect(subject.build(key_result, only_path: true)).to eq("/#{key_result.project.full_path}/-/work_items/#{key_result.id}")
        end
      end

      context 'when a work item is passed' do
        it 'returns a path using the work item\'s ID and no query params' do
          work_item = create(:work_item)

          expect(subject.build(work_item, only_path: true)).to eq("/#{work_item.project.full_path}/-/work_items/#{work_item.id}")
        end
      end
    end
  end
end
