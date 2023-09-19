# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NoteEntity do
  include Gitlab::Routing

  let(:issue) { create(:issue) }
  let(:description_version) { create(:description_version, issue: issue) }
  let(:note) { create(:system_note, project: issue.project, noteable: issue, system_note_metadata: create(:system_note_metadata, description_version: description_version)) }

  let(:request) { double('request', current_user: issue.author, noteable: issue) }
  let(:entity) { described_class.new(note, request: request) }

  subject { entity.as_json }

  context 'when description_diffs license is available' do
    before do
      stub_licensed_features(description_diffs: true)
    end

    it 'includes description versions attributes' do
      expect(subject[:description_version_id]).to eq(description_version.id)
      expect(subject[:description_diff_path]).to eq(description_diff_project_issue_path(issue.project, issue, description_version.id))
      expect(subject[:delete_description_version_path]).to eq(delete_description_version_project_issue_path(issue.project, issue, description_version.id))
      expect(subject[:can_delete_description_version]).to eq(true)
    end
  end

  context 'when description_diffs license is not available' do
    before do
      stub_licensed_features(description_diffs: false)
    end

    it 'does not include description versions attributes' do
      expect(subject[:description_version_id]).to be_nil
      expect(subject[:description_diff_path]).to be_nil
      expect(subject[:delete_description_version_path]).to be_nil
      expect(subject[:can_delete_description_version]).to be_nil
    end
  end
end
