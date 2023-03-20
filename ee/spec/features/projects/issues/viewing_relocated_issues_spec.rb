# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issues canonical link', feature_category: :team_planning do
  include Features::CanonicalLinkHelpers

  let(:epic) { create(:epic) }
  let(:project) { create(:project, :public, group: epic.group) }
  let(:original_issue) { create(:issue, project: project) }
  let(:canonical_url) { epic_url(epic) }

  context 'when the issue was promoted' do
    it 'shows the canonical URL' do
      original_issue.promoted_to_epic = epic
      original_issue.save!

      visit(issue_path(original_issue))

      expect(page).to have_canonical_link(canonical_url)
    end
  end
end
