# frozen_string_literal: true

require "spec_helper"

RSpec.describe Security::SecurityOrchestrationPolicies::PolicyBranchesService, feature_category: :security_policy_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_refind(:project) { create(:project, :empty_repo) }
  let_it_be(:default_branch) { "master" }
  let_it_be(:protected_branch) { "protected" }
  let_it_be(:unprotected_branch) { "feature" }
  let(:rules) { [rule] }

  before_all do
    sha = project.repository.create_file(
      project.creator,
      "README.md",
      "",
      message: "initial commit",
      branch_name: default_branch)

    [default_branch, protected_branch, unprotected_branch].each do |branch|
      project.repository.add_branch(project.creator, branch, sha)
    end

    [default_branch, protected_branch].each do |branch|
      project.protected_branches.create!(name: branch)
    end

    project.repository.raw_repository.write_ref("HEAD", "refs/heads/#{default_branch}")
  end

  %i[scan_execution_branches scan_result_branches].each do |method|
    describe method do
      subject(:execute) do
        Security::SecurityOrchestrationPolicies::PolicyBranchesService.new(project: project).public_send(method, rules)
      end

      describe "branches" do
        # rubocop: disable Performance/CollectionLiteralInLoop, Layout/LineLength
        where(:branches, :branch_type, :branch_exceptions, :result) do
          # branches
          ([]            | nil | nil | [])                   if method == :scan_execution_branches
          ([]            | nil | nil | %w[master protected]) if method == :scan_result_branches
          %w[foobar]     | nil | nil | []
          %w[master]     | nil | nil | %w[master]
          %w[mas* pro*]  | nil | nil | %w[master protected]

          # branch_type
          (nil | "all"        | nil | %w[master protected feature]) if method == :scan_execution_branches
          (nil | "all"        | nil | %w[master protected])         if method == :scan_result_branches
          nil  | "protected"  | nil | %w[master protected]
          nil  | "default"    | nil | %w[master]
          nil  | "invalid"    | nil | []

          # branch_exceptions
          %w[mas* pro*]    | nil     | %w[master]                                                  | %w[protected]
          %w[mas* pro*]    | nil     | %w[pro*]                                                    | %w[master]
          %w[mas* pro*]    | nil     | [{ name: "master", full_path: lazy { project.full_path } }] | %w[protected]
          %w[mas* pro*]    | nil     | [{ name: "master", full_path: "other" }]                    | %w[master protected]
          nil              | "all"   | %w[*]                                                       | []

          # invalid branch_exceptions
          nil | "protected" | [{}] | %w[master protected]
          nil | "protected" | [{ name: "master" }] | %w[master protected]
          nil | "protected" | [{ full_path: lazy { project.full_path } }] | %w[master protected]
        end
        # rubocop: enable Performance/CollectionLiteralInLoop, Layout/LineLength

        with_them do
          let(:rule) { { branch_type: branch_type, branches: branches, branch_exceptions: branch_exceptions }.compact }

          specify do
            expect(execute).to eq(result.to_set)
          end
        end
      end

      context "with agent" do
        let(:rule) { { agents: { production: {} } } }

        specify do
          expect(execute).to be_empty
        end
      end

      if method == :scan_result_branches
        context "with unprotected default branch" do
          let(:rule) { { branch_type: "default" } }

          before do
            project.protected_branches.find_by!(name: default_branch).delete
          end

          specify do
            expect(execute).to be_empty
          end
        end
      end

      context "with multiple rules" do
        let(:rules) do
          [
            { branch_type: "default" },
            { branch_type: "protected" },
            { branches: [unprotected_branch] }
          ]
        end

        let(:expected_branches) do
          case method
          when :scan_execution_branches then [default_branch, protected_branch, unprotected_branch]
          when :scan_result_branches then [default_branch, protected_branch]
          end
        end

        specify do
          expect(execute).to contain_exactly(*expected_branches)
        end
      end

      context "with group-level protected branches" do
        let_it_be(:group) { create(:group) }
        let(:rule) { { branch_type: "protected" } }
        let(:branch_name) { "develop" }
        let(:method) { :scan_execution_branches }

        before do
          project.group = group
          project.save!

          group.protected_branches.create!(name: branch_name)

          project.repository.add_branch(project.creator, branch_name, project.repository.head_commit.sha)
        end

        after do
          project.repository.delete_branch(branch_name)
        end

        specify do
          expect(execute).to include(branch_name)
        end

        context "with feature disabled" do
          before do
            stub_feature_flags(group_protected_branches: false)
            stub_feature_flags(allow_protected_branches_for_group: false)
          end

          specify do
            expect(execute).to exclude(branch_name)
          end
        end
      end

      context "with empty repository" do
        let_it_be(:project) { create(:project, :empty_repo) }

        let(:rule) { { branch_type: "all" } }

        specify do
          expect(execute).to be_empty
        end
      end
    end
  end
end
