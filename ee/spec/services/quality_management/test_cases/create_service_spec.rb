# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QualityManagement::TestCases::CreateService, feature_category: :quality_management do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, :empty_repo) }
  let_it_be(:label) { create(:label, project: project) }

  let(:title) { 'test case title' }
  let(:description) { 'test case description' }
  let(:confidential) { true }
  let(:new_issue) { Issue.last! }
  let(:params) do
    {
      title: title,
      description: description,
      label_ids: [label.id],
      confidential: confidential
    }
  end

  let(:service) do
    described_class.new(
      project,
      user,
      params: params
    )
  end

  describe '#execute' do
    subject { service.execute }

    shared_examples 'creates a test case issue' do
      specify :aggregate_failures do
        expect { subject }.to change(Issue, :count).by(1)

        expect(subject).to be_success

        expect(new_issue.title).to eq(expected_title)
        expect(new_issue.description).to eq(expected_description)
        expect(new_issue.author).to eq(user)
        expect(new_issue.issue_type).to eq('test_case')
        expect(new_issue.labels.map(&:title)).to eq(expected_label_titles)
        expect(new_issue.confidential).to eq(expected_confidentiality)
      end
    end

    before_all do
      project.add_reporter(user)
    end

    before do
      stub_licensed_features(quality_management: true)
    end

    context 'when all permitted params are provided' do
      let(:expected_title) { title }
      let(:expected_description) { description }
      let(:expected_label_titles) { [label.title] }
      let(:expected_confidentiality) { confidential }

      it_behaves_like 'creates a test case issue'
    end

    context 'when only required params are provided' do
      let(:expected_title) { title }
      let(:expected_description) { nil }
      let(:expected_label_titles) { [] }
      let(:expected_confidentiality) { false }
      let(:params) { { title: title } }

      it_behaves_like 'creates a test case issue'
    end

    context 'when a param is provided that is not allowed' do
      let(:params) { super().merge(assignee_ids: [user.id]) }

      it 'creates a test case issue ignoring forbidden params' do
        expect { subject }.to change(Issue, :count).by(1)

        expect(subject).to be_success

        expect(new_issue.assignees).to be_empty
      end
    end

    context 'when test case has no title' do
      let(:title) { '' }

      it 'does not create an issue', :aggregate_failures do
        expect { subject }.not_to change(Issue, :count)

        expect(subject).to be_error
        expect(subject.errors).to contain_exactly("Title can't be blank")

        expect(subject.payload[:issue]).to be_kind_of(Issue)
      end
    end
  end
end
