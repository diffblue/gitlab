# frozen_string_literal: true

require 'rspec-parameterized'
require 'gitlab-dangerfiles'
require 'danger'
require 'danger/plugins/internal/helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/specs'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::Specs, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double('Tooling::Danger::ProjectHelper') }
  let(:filename) { 'spec/foo_spec.rb' }

  subject(:specs) { fake_danger.new(helper: fake_helper) }

  before do
    allow(specs).to receive(:project_helper).and_return(fake_project_helper)
  end

  describe '#changed_specs_files' do
    let(:base_expected_files) { %w[spec/foo_spec.rb ee/spec/foo_spec.rb spec/bar_spec.rb ee/spec/bar_spec.rb spec/zab_spec.rb ee/spec/zab_spec.rb] }

    before do
      all_changed_files = %w[
        app/workers/a.rb
        app/workers/b.rb
        app/workers/e.rb
        spec/foo_spec.rb
        ee/spec/foo_spec.rb
        spec/bar_spec.rb
        ee/spec/bar_spec.rb
        spec/zab_spec.rb
        ee/spec/zab_spec.rb
      ]

      allow(specs.helper).to receive(:all_changed_files).and_return(all_changed_files)
    end

    it 'returns added, modified, and renamed_after files by default' do
      expect(specs.changed_specs_files).to match_array(base_expected_files)
    end

    context 'with include_ee: :exclude' do
      it 'returns spec files without EE-specific files' do
        expect(specs.changed_specs_files(ee: :exclude)).not_to include(%w[ee/spec/foo_spec.rb ee/spec/bar_spec.rb ee/spec/zab_spec.rb])
      end
    end

    context 'with include_ee: :only' do
      it 'returns EE-specific spec files only' do
        expect(specs.changed_specs_files(ee: :only)).to match_array(%w[ee/spec/foo_spec.rb ee/spec/bar_spec.rb ee/spec/zab_spec.rb])
      end
    end
  end

  describe '#add_suggestions_for_feature_category' do
    before do
      allow(specs.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
      allow(specs.project_helper).to receive(:file_lines).and_return(file_lines)
    end

    let(:template) do
      <<~SUGGESTION_MARKDOWN.chomp
      ```suggestion
      %<suggested_line>s
      ```

      Consider adding `feature_category: <feature_category_name>` for this example if it is not set already.
      See [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#feature-category-metadata).
      SUGGESTION_MARKDOWN
    end

    let(:file_lines) do
      [
        " require 'spec_helper'",
        " \n",
        " RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController, feature_category: :planning_analytics do",
        " end",
        "RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController do",
        "  let_it_be(:user) { create(:user) }",
        " end",
        " describe 'GET \"time_summary\"' do",
        " end",
        " RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController do",
        "  let_it_be(:user) { create(:user) }",
        " end",
        " describe 'GET \"time_summary\"' do",
        " end",
        " \n",
        "RSpec.describe Projects :aggregate_failures,",
        "  feature_category: planning_analytics do",
        " \n",
        "RSpec.describe Epics :aggregate_failures,",
        "  ee: true do",
        "\n",
        "RSpec.describe Issues :aggregate_failures,",
        "  feature_category: :team_planning do",
        "\n",
        "RSpec.describe MergeRequest :aggregate_failures,",
        "  :js,",
        "  feature_category: :team_planning do"
      ]
    end

    let(:changed_lines) do
      [
        "+ RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController, feature_category: :planning_analytics do",
        "+RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController do",
        "+ let_it_be(:user) { create(:user) }",
        "- end",
        "+ describe 'GET \"time_summary\"' do",
        "+ RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController do",
        "+RSpec.describe Projects :aggregate_failures,",
        "+  feature_category: planning_analytics do",
        "+RSpec.describe Epics :aggregate_failures,",
        "+  ee: true do",
        "+RSpec.describe Issues :aggregate_failures,",
        "+RSpec.describe MergeRequest :aggregate_failures,",
        "+  :js,",
        "+  feature_category: :team_planning do",
        "+RSpec.describe 'line in commit diff but no longer in working copy' do"
      ]
    end

    before do
      allow(specs.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
    end

    it 'adds suggestions at the correct lines', :aggregate_failures do
      [
        { suggested_line: "RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController do", number: 5 },
        { suggested_line: " RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController do", number: 10 },
        { suggested_line: "RSpec.describe Epics :aggregate_failures,", number: 19 }

      ].each do |test_case|
        comment = format(template, suggested_line: test_case[:suggested_line])
        expect(specs).to receive(:markdown).with(comment, file: filename, line: test_case[:number])
      end

      specs.add_suggestions_for_feature_category(filename)
    end
  end
end
