# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::CreateVisualReviewService, feature_category: :review_apps do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:current_user) { create(:user) }
  let(:body) { 'BODY' }

  before do
    project.add_developer(current_user)
  end

  subject { described_class.new(merge_request, current_user, body: body).execute }

  context 'when merge request discussion is unlocked' do
    let!(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project)
    end

    it 'creates a note' do
      expect { subject }.to change { merge_request.notes.count }.by(1)
    end
  end

  context 'when merge request discussion is locked' do
    let!(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project, discussion_locked: true)
    end

    it 'does not create a note' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when project is archived' do
    let(:archived_project) { create(:project, :public, :repository, :archived) }
    let!(:merge_request) do
      create(:merge_request_with_diffs, source_project: archived_project, target_project: archived_project)
    end

    before do
      archived_project.add_developer(current_user)
    end

    it 'does not create a note' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end
