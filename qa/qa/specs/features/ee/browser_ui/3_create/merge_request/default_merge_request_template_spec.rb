# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Default merge request templates', product_group: :code_review do
      let(:default_template_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'default-mr-template-project'
        end
      end

      let(:template_content) { 'This is a default merge request template' }

      before do
        Flow::Login.sign_in
      end

      it 'uses default template when creating a merge request', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347721' do
        default_template_project.visit!

        Page::Project::Menu.perform(&:go_to_merge_request_settings)
        Page::Project::Settings::MergeRequest.perform do |settings|
          settings.set_default_merge_request_template(template_content)
        end

        Resource::MergeRequest.fabricate_via_browser_ui! do |merge_request|
          merge_request.project = default_template_project
          merge_request.description = nil
        end

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_description(template_content)
        end
      end
    end
  end
end
