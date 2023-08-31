# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Templates::SummarizeMergeRequest, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:merge_request) do
    create(
      :merge_request,
      source_branch: 'feature',
      target_branch: 'master',
      source_project: project,
      target_project: project
    )
  end

  let_it_be(:mr_diff) { merge_request.merge_request_diff }

  subject { described_class.new(merge_request, mr_diff) }

  describe '#to_prompt' do
    it 'includes title param' do
      expect(subject.to_prompt).to include(merge_request.title)
    end

    it 'includes raw diff' do
      expect(subject.to_prompt)
        .to include("+class Feature\n+  def foo\n+    puts 'bar'\n+  end\n+end")
    end
  end
end
