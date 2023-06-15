# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::IncidentEntity, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }

  let_it_be(:issue, reload: true) do
    create(:issue, title: ':ok:', description: ':tada:', author: user)
  end

  let(:json) { subject.as_json }

  subject { described_class.new(issue, user_notes: [], issue_iid: issue.iid) }

  it 'exposes JSON fields' do
    expect(json).to eq(
      id: issue.iid,
      status: issue.state,
      title: issue.title_html,
      description: issue.description_html,
      updated_at: issue.updated_at,
      created_at: issue.created_at,
      comments: [],
      links: { details: "data/incident/#{issue.iid}.json" }
    )
  end

  it 'exposes correct data types' do
    expect(json.to_json).to match_schema('status_page/incident_details', dir: 'ee')
  end

  describe 'field #title' do
    it_behaves_like 'reference links for status page' do
      let(:object) { issue }
      let(:field) { :title }
      let(:value) { json[:title] }
    end
  end

  describe 'field #description' do
    it_behaves_like 'reference links for status page' do
      let(:object) { issue }
      let(:field) { :description }
      let(:value) { json[:description] }
    end

    it_behaves_like 'img upload tags for status page' do
      let(:object) { issue }
      let(:field) { :description }
      let(:value) { json[:description] }
    end
  end

  context 'with user notes' do
    let(:user_notes) do
      create_list(:note, 1, noteable: issue, project: issue.project)
    end

    subject { described_class.new(issue, user_notes: user_notes, issue_iid: issue.iid) }

    it 'exposes comments' do
      expect(json).to include(:comments)
      expect(json[:comments].size).to eq(1)
    end
  end
end
