# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::BuildService, feature_category: :code_review_workflow do
  let(:source_project) { project }
  let(:target_project) { project }
  let(:user) { create(:user) }
  let(:description) { nil }
  let(:source_branch) { 'feature' }
  let(:target_branch) { 'master' }
  let(:merge_request) { service.execute }
  let(:compare) { double(:compare, commits: commits) }
  let(:commit_1) { double(:commit_1, safe_message: "Initial commit\n\nCreate the app") }
  let(:commit_2) { double(:commit_2, safe_message: 'This is a bad commit message!') }
  let(:commits) { nil }

  let(:service) do
    described_class.new(
      project: project,
      current_user: user,
      params: {
        description: description,
        source_branch: source_branch,
        target_branch: target_branch,
        source_project: source_project,
        target_project: target_project
      }
    )
  end

  before do
    allow(service).to receive(:branches_valid?) { true }
  end

  context 'project default template configured' do
    let(:template) { "I am the template, you fill me in" }
    let(:project) { create(:project, :repository, merge_requests_template: template) }

    context 'issuable default templates feature not available' do
      before do
        stub_licensed_features(issuable_default_templates: false)
      end

      it 'does not set the MR description from template' do
        expect(merge_request.description).not_to eq(template)
      end

      context 'when description is provided' do
        let(:description) { 'Description' }

        it "sets the user's description" do
          expect(merge_request.description).to eq(description)
        end
      end
    end

    context 'issuable default templates feature available' do
      before do
        stub_licensed_features(issuable_default_templates: true)
      end

      it 'sets the MR description from template' do
        expect(merge_request.description).to eq(template)
      end

      context 'when description is provided' do
        let(:description) { 'Description' }

        it "prefers user's description to the default template" do
          expect(merge_request.description).to eq(description)
        end
      end

      context 'a Default.md file exists in the repository' do
        let(:files) { { '.gitlab/merge_request_templates/Default.md' => 'Default template contents' } }
        let(:project) { create(:project, :repository, :custom_repo, merge_requests_template: template, files: files ) }

        it 'prefers the project default template' do
          expect(merge_request.description).to eq(template)
        end
      end

      context 'when MR is set to close an issue' do
        let(:issue) { create(:issue, project: project) }

        let(:service) do
          described_class.new(
            project: project,
            current_user: user,
            params: {
              description: description,
              source_branch: source_branch,
              target_branch: target_branch,
              source_project: source_project,
              target_project: target_project,
              issue_iid: issue.iid
            })
        end

        before do
          project.add_guest(user)
        end

        it 'appends closing reference once' do
          expect(merge_request.description).to eq(template + "\n\nCloses ##{issue.iid}")
        end
      end
    end
  end
end
