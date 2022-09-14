# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::LinkedIssueFeatureFlagEntity do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }

  before_all do
    project.add_developer(developer)
  end

  describe '#as_json' do
    it 'returns json' do
      issue = create(:issue, project: project)
      feature_flag = create(:operations_feature_flag, project: project)
      link = create(:feature_flag_issue, feature_flag: feature_flag, issue: issue)
      allow(issue).to receive(:link_id).and_return(link.id)
      request = double('request')
      allow(request).to receive(:current_user).and_return(developer)
      allow(request).to receive(:issuable).and_return(issue)
      entity = described_class.new(feature_flag, request: request, current_user: developer)

      expect(entity.as_json.slice(:link_type, :path, :reference)).to eq({
        link_type: 'relates_to',
        path: "/#{project.full_path}/-/feature_flags/#{feature_flag.iid}/edit",
        reference: "[feature_flag:#{feature_flag.iid}]"
      })
    end
  end
end
