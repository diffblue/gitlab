# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', product_group: :import_and_integrate do
    describe 'GitHub import' do
      include_context 'with github import'

      context "when imported via api" do
        before do
          QA::Support::Helpers::ImportSource.enable('github')
        end

        it 'imports repo push rules', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/379494' do
          expect_project_import_finished_successfully

          aggregate_failures do
            verify_push_rules
            verify_protected_branches_import
          end
        end

        def verify_push_rules
          # GitHub branch protection rule "Require signed commits" is mapped to the "Reject unsigned commits" push rule
          expect(imported_project.push_rules[:reject_unsigned_commits]).to be_truthy
        end

        def verify_protected_branches_import
          imported_branches = imported_project.protected_branches.map do |branch|
            branch.slice(:name, :allow_force_push, :code_owner_approval_required)
          end
          actual_branches = [
            {
              name: 'main',
              allow_force_push: false,
              code_owner_approval_required: true
            },
            {
              name: 'release',
              allow_force_push: true,
              code_owner_approval_required: true
            }
          ]

          expect(imported_branches).to match_array(actual_branches)
        end
      end
    end
  end
end
