# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Validate code owner file', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { project.first_owner }
  let_it_be(:code_owners_path) { ::Gitlab::CodeOwners::FILE_NAME }

  let(:query) do
    <<~QUERY
    query {
      project(fullPath: "#{project.full_path}") {
        repository {
          validateCodeownerFile(ref:#{ref.inspect}) {
            total
            validationErrors {
              code
              lines
            }
          }
        }
      }
    }
    QUERY
  end

  let(:validation) { execute.dig("data", "project", "repository", "validateCodeownerFile") }
  let(:errors) { execute["errors"] }

  subject(:execute) { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

  context 'when ref has no code owners file' do
    let(:query) do
      <<~QUERY
      query {
        project(fullPath: "#{project.full_path}") {
          repository {
            validateCodeownerFile {
              total
              validationErrors {
                code
                lines
              }
            }
          }
        }
      }
      QUERY
    end

    it 'returns nil for the validateCodeownerFile field' do
      expect(validation).to eq(nil)
      expect(errors).to eq(nil)
    end
  end

  context 'with no path argument' do
    let_it_be(:code_owners_path) { ".gitlab/#{::Gitlab::CodeOwners::FILE_NAME}" }
    let_it_be(:ref) { "no-path-request" }

    let_it_be(:code_owners_content) do
      <<~CODEOWNERS
      docs/*
      CODEOWNERS
    end

    before_all do
      project.repository.create_file(
        current_user,
        code_owners_path,
        code_owners_content,
        branch_name: ref,
        message: 'initial codeowners'
      )
    end

    it 'returns nil for the validateCodeownerFile field' do
      expect(validation["total"]).to eq(1)
    end
  end

  context 'with the path argument' do
    let_it_be(:code_owners_path) { "invalid_folder/#{::Gitlab::CodeOwners::FILE_NAME}" }
    let_it_be(:bad_path) { 'README.md' }

    let_it_be(:code_owners_content) do
      <<~CODEOWNERS
      [Documentation
      docs/*
      docs/CODEOWNERS @owner-1 owner2@gitlab.org @owner-3 @documentation-owner
      [Testing]
      spec/* @test-owner @test-group @test-group/nested-group
      CODEOWNERS
    end

    let(:query) do
      <<~QUERY
      query {
        project(fullPath: "#{project.full_path}") {
          repository {
            validateCodeownerFile(path:#{path.inspect}) {
              total
              validationErrors {
                code
                lines
              }
            }
          }
        }
      }
      QUERY
    end

    before_all do
      project.repository.create_file(
        current_user,
        code_owners_path,
        code_owners_content,
        branch_name: project.repository.root_ref,
        message: 'bad code owners'
      )
    end

    context 'when path does lead to a file named CODEOWNERS' do
      let(:path) { code_owners_path }

      it 'validates the file on that path' do
        expected_errors = [
          { "code" => "invalid_section_format", "lines" => [1] },
          { "code" => "missing_entry_owner", "lines" => [1, 2] }
        ]

        expect(validation)
          .to eq({ "total" => 3, "validationErrors" => expected_errors })
      end
    end

    context 'when path does not lead to a file named correctly' do
      let(:path) { bad_path }

      it 'returns nil for the validateCodeownerFile field' do
        expect(validation).to eq(nil)
        expect(errors).to eq(nil)
      end
    end

    context 'when path does not lead to an existing file' do
      let(:path) { "random/path/to_not_existing/#{::Gitlab::CodeOwners::FILE_NAME}" }

      it 'returns nil for the validateCodeownerFile field' do
        expect(validation).to eq(nil)
        expect(errors).to eq(nil)
      end
    end
  end

  context 'when code owners file is empty' do
    let_it_be(:ref) { 'empty-branch' }

    before_all do
      project.repository.create_file(current_user, code_owners_path, '', branch_name: ref, message: 'empty code owners')
    end

    it 'returns no error in validateCodeownerFile field' do
      expect(validation).to eq({ "total" => 0, "validationErrors" => [] })
    end
  end

  context 'when code owner file has linting errors' do
    let_it_be(:ref) { 'bad-branch' }

    let_it_be(:code_owners_content) do
      <<~CODEOWNERS
      [Documentation]
      docs/*
      docs/CODEOWNERS @owner-1 owner2@gitlab.org @owner-3 @documentation-owner
      [Testing
      spec/* @test-owner @test-group @test-group/nested-group
      CODEOWNERS
    end

    before_all do
      project.repository.create_file(
        current_user,
        code_owners_path,
        code_owners_content,
        branch_name: ref,
        message: 'bad code owners'
      )
    end

    it 'returns no error in validateCodeownerFile field' do
      expected_errors = [
        { "code" => "missing_entry_owner", "lines" => [2, 4] },
        { "code" => "invalid_section_format", "lines" => [4] }
      ]

      expect(validation)
        .to eq({ "total" => 3, "validationErrors" => expected_errors })
    end
  end

  context 'when code owners file is correct' do
    let_it_be(:ref) { 'good-branch' }

    let_it_be(:code_owners_content) do
      <<~CODEOWNERS
      docs/* @documentation-owner
      docs/CODEOWNERS @owner-1 owner2@gitlab.org @owner-3 @documentation-owner
      spec/* @test-owner @test-group @test-group/nested-group
      CODEOWNERS
    end

    before_all do
      project.repository.create_file(
        current_user,
        code_owners_path,
        code_owners_content,
        branch_name: ref,
        message: 'good code owners'
      )
    end

    it 'returns no error in validateCodeownerFile field' do
      expect(validation).to eq({ "total" => 0, "validationErrors" => [] })
    end
  end
end
