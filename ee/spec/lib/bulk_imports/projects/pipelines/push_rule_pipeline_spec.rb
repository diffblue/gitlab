# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::PushRulePipeline do
  let_it_be(:project) { create(:project) }
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, :project_entity, project: project, bulk_import: bulk_import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:push_rule) do
    {
      'force_push_regex' => 'MustContain',
      'delete_branch_regex' => 'MustContain',
      'commit_message_regex' => 'MustContain',
      'author_email_regex' => 'MustContain',
      'file_name_regex' => 'MustContain',
      'branch_name_regex' => 'MustContain',
      'commit_message_negative_regex' => 'MustNotContain',
      'max_file_size' => 1,
      'deny_delete_tag' => true,
      'member_check' => true,
      'is_sample' => true,
      'prevent_secrets' => true,
      'reject_unsigned_commits' => true,
      'commit_committer_check' => true,
      'regexp_uses_re2' => true
    }
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run' do
    it 'imports push rules', :aggregate_failures do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [[push_rule, 0]]))
      end

      expect { pipeline.run }.to change { PushRule.count }.from(0).to(1)

      imported_push_rule = project.push_rule

      push_rule.each_pair do |key, value|
        expect(imported_push_rule.public_send(key)).to eq(value)
      end
    end
  end
end
