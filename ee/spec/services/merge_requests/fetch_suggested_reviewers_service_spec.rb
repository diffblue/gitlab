# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::FetchSuggestedReviewersService, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  subject(:service) { described_class.new(project: project).execute(merge_request) }

  describe '#execute' do
    let(:example_model_result) do
      {
        version: '0.1.0',
        top_n: 1,
        reviewers: ['root']
      }
    end

    let(:example_result) do
      example_model_result.merge({ status: :success })
    end

    let(:model_input) do
      {
        project_id: merge_request.project_id,
        merge_request_iid: merge_request.iid,
        changes: [
          'bar/branch-test.txt',
          'custom-highlighting/test.gitlab-custom',
          'encoding/iso8859.txt',
          'files/images/wm.svg',
          'files/js/commit.coffee',
          'files/js/commit.js.coffee',
          'files/lfs/lfs_object.iso',
          'files/ruby/popen.rb',
          'files/ruby/regex.rb',
          'files/.DS_Store',
          'files/whitespace',
          'foo/bar/.gitkeep',
          'with space/README.md',
          '.DS_Store',
          '.gitattributes',
          '.gitignore',
          '.gitmodules',
          'CHANGELOG',
          'README',
          'gitlab-grack',
          'gitlab-shell'
        ],
        author_username: merge_request.author.username
      }
    end

    it 'sends the machine learning model input to the suggested reviewers client' do
      stub_env('SUGGESTED_REVIEWERS_SECRET', SecureRandom.hex(32))

      expect_next_instance_of(Gitlab::AppliedMl::SuggestedReviewers::Client) do |client|
        expect(client).to receive(:suggested_reviewers).with(model_input).and_return(example_model_result)
      end

      expect(service[:status]).to eq(:success)
    end

    it 'returns an empty result when changes are empty' do
      allow(merge_request).to receive(:modified_paths).and_return([])

      expect(service)
        .to eq({ status: :error, message: 'Merge request contains no modified files' })
    end
  end
end
