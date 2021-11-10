# frozen_string_literal: true

module QA
  # TODO: Remove :requires_admin when the `Runtime::Feature.enable` method call is removed
  RSpec.describe 'Plan', :requires_admin do
    describe 'Editing scoped labels on issues' do
      let(:initial_label) { 'animal::fox' }
      let(:new_label_same_scope) { 'animal::dolphin' }
      let(:new_label_different_scope) { 'plant::orchid' }

      let(:initial_label_multi_colon) { 'group::car::ferrari' }
      let(:new_label_same_scope_multi_colon) { 'group::car::porsche' }
      let(:new_label_different_scope_multi_colon) { 'group::truck::mercedes-bens' }

      let!(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.labels = [initial_label, initial_label_multi_colon]
        end
      end

      before do
        Runtime::Feature.enable(:labels_widget, project: issue.project)

        Flow::Login.sign_in

        [
          new_label_same_scope,
          new_label_different_scope,
          new_label_same_scope_multi_colon,
          new_label_different_scope_multi_colon
        ].each do |label|
          Resource::ProjectLabel.fabricate_via_api! do |l|
            l.project = issue.project
            l.title = label
          end
        end

        issue.visit!
      end

      it(
        'correctly applies simple and multiple colon scoped pairs labels',
        testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1181'
      ) do
        Page::Project::Issue::Show.perform do |show|
          # TODO: Remove this method when the `Runtime::Feature.enable` method call is removed
          show.wait_for_labels_widget_feature_flag

          show.select_labels(
            [
              new_label_same_scope,
              new_label_different_scope,
              new_label_same_scope_multi_colon,
              new_label_different_scope_multi_colon
            ]
          )

          aggregate_failures do
            expect(show).to have_label(new_label_same_scope)
            expect(show).to have_label(new_label_different_scope)
            expect(show).to have_label(new_label_same_scope_multi_colon)
            expect(show).to have_label(new_label_different_scope_multi_colon)

            expect(show).not_to have_label(initial_label)
            expect(show).not_to have_label(initial_label_multi_colon)
          end
        end
      end
    end
  end
end
