# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlobController, feature_category: :source_code_management do
  include ProjectForksHelper
  include FakeBlobHelpers

  let(:project) { create(:project, :public, :repository) }

  shared_examples_for "handling the codeowners interaction" do
    it "redirects to blob" do
      default_params[:file_path] = "docs/EXAMPLE_FILE"

      subject

      expect(flash[:alert]).to eq(nil)
      expect(response).to be_redirect
    end
  end

  describe 'POST create' do
    let(:user) { create(:user) }
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master',
        branch_name: 'master',
        file_name: 'docs/EXAMPLE_FILE',
        content: 'Added changes',
        commit_message: 'Create CHANGELOG'
      }
    end

    before do
      project.add_developer(user)

      sign_in(user)
    end

    it 'redirects to blob' do
      post :create, params: default_params

      expect(response).to be_redirect
    end

    it_behaves_like "handling the codeowners interaction" do
      subject { post :create, params: default_params }

      let(:expected_view) { :new }
    end
  end

  describe 'PUT update' do
    let(:user) { create(:user) }
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/CHANGELOG',
        branch_name: 'master',
        content: 'Added changes',
        commit_message: 'Update CHANGELOG'
      }
    end

    before do
      project.add_maintainer(user)

      sign_in(user)
    end

    it_behaves_like "handling the codeowners interaction" do
      subject { put :update, params: default_params }

      let(:expected_view) { :edit }
    end
  end
end
