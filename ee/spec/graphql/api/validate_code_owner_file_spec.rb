# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Validate code owner file', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { project.first_owner }
  let_it_be(:code_owner_path) { "CODEOWNERS" }

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
    end
  end

  context 'when code owners file is correct' do
    let_it_be(:ref) { 'empty-branch' }

    before :all do
      project.repository.create_file(current_user, code_owner_path, '', branch_name: ref, message: 'empty code owners')
    end

    it 'returns no error in validateCodeownerFile field' do
      expect(validation).to eq(nil)
    end
  end

  context 'when paths lead to a code owners file' do
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

      before :all do
        project.repository.create_file(
          current_user,
          code_owner_path,
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

      before :all do
        project.repository.create_file(
          current_user,
          code_owner_path,
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
end
