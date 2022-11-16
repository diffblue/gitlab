# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::WithIssuesFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }
  let_it_be(:epic_without_issues) { create(:epic, group: group) }
  let_it_be(:epic_issue1) { create(:issue, project: project, epic: epic1) }
  let_it_be(:epic_issue2) { create(:issue, project: project, epic: epic2) }

  let(:accessible_epics) { Epic.id_in([epic1, epic2]) }
  let(:accessible_issues) { Issue.id_in([epic_issue1, epic_issue2]) }

  subject { described_class.new(accessible_epics: accessible_epics, accessible_issues: accessible_issues).execute }

  shared_examples 'returns correct epic results' do
    it 'returns epics' do
      expect(subject).to match_array(expected_epics)
    end
  end

  context 'when there are no accessible_epics' do
    let(:accessible_epics) { Epic.none }
    let(:expected_epics) { [] }

    it_behaves_like 'returns correct epic results'
  end

  context 'when there are no accessible_issues' do
    let(:accessible_epics) { Issue.none }
    let(:expected_epics) { [] }

    it_behaves_like 'returns correct epic results'
  end

  context 'when all epics are accessible' do
    let(:accessible_epics) { Epic.id_in([epic1, epic2, epic_without_issues]) }
    let(:accessible_issues) { Issue.id_in([epic_issue1, epic_issue2]) }
    let(:expected_epics) { [epic1, epic2] }

    it_behaves_like 'returns correct epic results'
  end

  context 'when filtered by accessible_epics' do
    let(:accessible_epics) { Epic.id_in([epic1]) }
    let(:accessible_issues) { Issue.id_in([epic_issue1, epic_issue2]) }
    let(:expected_epics) { [epic1] }

    it_behaves_like 'returns correct epic results'
  end

  context 'when filtered by accessible_issues' do
    let(:accessible_epics) { Epic.id_in([epic1, epic2]) }
    let(:accessible_issues) { Issue.id_in([epic_issue2]) }
    let(:expected_epics) { [epic2] }

    it_behaves_like 'returns correct epic results'
  end
end
