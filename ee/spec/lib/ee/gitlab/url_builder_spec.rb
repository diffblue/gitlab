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

      [:issue, :objective]   | ->(issue)         { "/#{issue.project.full_path}/-/work_items/#{issue.iid}" }
      [:issue, :key_result]  | ->(issue)         { "/#{issue.project.full_path}/-/work_items/#{issue.iid}" }
    end

    with_them do
      let(:object) { build_stubbed(*Array(factory)) }
      let(:path) { path_generator.call(object) }
      before do
        stub_licensed_features(okrs: true)
      end

      it 'returns the full URL' do
        expect(subject.build(object)).to eq("#{Settings.gitlab['url']}#{path}")
      end

      it 'returns only the path if only_path is set' do
        expect(subject.build(object, only_path: true)).to eq(path)
      end
    end
  end
end
