# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiffPolicy, feature_category: :code_review_workflow do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  subject(:policy) { described_class.new(user, merge_request.merge_request_diff) }

  context 'when user is not permitted to read merge request' do
    it { is_expected.to be_disallowed(:read_merge_request) }
  end

  context 'when user is permitted to read merge request' do
    before_all do
      project.add_developer(user)
    end

    it { is_expected.to be_allowed(:read_merge_request) }
  end
end
