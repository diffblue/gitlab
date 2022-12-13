# frozen_string_literal: true

require 'spec_helper'

# See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
# for documentation on this spec.
RSpec.describe API::Markdown, 'Snapshot', feature_category: :team_planning do
  # noinspection RailsParamDefResolve (RubyMine can't find the shared context from this file location)
  include_context 'with API::Markdown Snapshot shared context', ee_only: true
end
