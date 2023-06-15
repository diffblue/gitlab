# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::IncidentCommentEntity, feature_category: :incident_management do
  let_it_be(:note, reload: true) { create(:note, note: ':ok:') }

  let(:json) { subject.as_json }
  let(:issue) { instance_double(Issue, iid: 1) }

  subject { described_class.new(note, issue_iid: issue.iid) }

  it 'exposes JSON fields' do
    expect(json).to eq(
      note: note.note_html,
      created_at: note.created_at
    )
  end

  describe 'field #note' do
    it_behaves_like 'reference links for status page' do
      let(:object) { note }
      let(:field) { :note }
      let(:value) { json[:note] }
    end

    it_behaves_like 'img upload tags for status page' do
      let(:object) { note }
      let(:field) { :note }
      let(:value) { json[:note] }
    end
  end
end
