# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QualityManagement::TestCases::CreateService do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, :empty_repo) }
  let(:description) { 'test case description' }
  let_it_be(:label) { create(:label, project: project) }

  let(:service) { described_class.new(project, user, title: title, description: description, label_ids: [label.id]) }

  describe '#execute' do
    before_all do
      project.add_reporter(user)
    end

    before do
      stub_licensed_features(quality_management: true)
    end

    context 'when test has title and description' do
      let(:title) { 'test case title' }
      let(:new_issue) { Issue.last! }

      it 'responds with success' do
        expect(service.execute).to be_success
      end

      it 'creates an test case issue' do
        expect { service.execute }.to change(Issue, :count).by(1)
      end

      it 'created issue has correct attributes' do
        service.execute
        aggregate_failures do
          expect(new_issue.title).to eq(title)
          expect(new_issue.description).to eq(description)
          expect(new_issue.author).to eq(user)
          expect(new_issue.issue_type).to eq('test_case')
          expect(new_issue.labels.map(&:title)).to eq([label.title])
        end
      end
    end

    context 'when test case has no title' do
      let(:title) { '' }

      it 'does not create an issue' do
        expect { service.execute }.not_to change(Issue, :count)
      end

      it 'responds with errors' do
        result = service.execute

        expect(result).to be_error
        expect(result.errors).to contain_exactly("Title can't be blank")
      end

      it 'result payload contains an Issue object' do
        expect(service.execute.payload[:issue]).to be_kind_of(Issue)
      end
    end
  end
end
