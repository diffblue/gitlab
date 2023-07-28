# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::MergeRequestsService, feature_category: :code_review_workflow do
  include Gitlab::Routing

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:author) { create(:user) }

  let(:noteable) { create(:merge_request, source_project: project, target_project: project) }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '.merge_when_checks_pass' do
    let(:pipeline) { build(:ci_pipeline) }

    subject { service.merge_when_checks_pass(pipeline.sha) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when checks pass' system note" do
      expect(subject.note).to(
        match("enabled an automatic merge when all merge checks for #{pipeline.sha} pass")
      )
    end
  end
end
