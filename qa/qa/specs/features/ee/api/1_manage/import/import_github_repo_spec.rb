# frozen_string_literal: true

module QA
  # https://github.com/gitlab-qa-github/import-test <- project under test
  #
  RSpec.describe 'Manage', product_group: :import do
    describe 'GitHub import' do
      include_context 'with github import'

      context "when imported via api" do
        it 'imports repo push rules', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/379494' do
          imported_project.reload! # import the project

          expect { imported_project.project_import_status[:import_status] }.to eventually_eq('finished')
            .within(max_duration: 240, sleep_interval: 1)

          # GitHub branch protection rule "Require signed commits" is mapped to the "Reject unsigned commits" push rule
          expect(imported_project.push_rules[:reject_unsigned_commits]).to be_truthy
        end
      end
    end
  end
end
