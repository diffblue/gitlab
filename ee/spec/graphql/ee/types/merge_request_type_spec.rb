# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequest'] do
  it { expect(described_class).to have_graphql_fields(:approvals_required, :merge_trains_count, :approval_state).at_least }
  it { expect(described_class).to have_graphql_field(:approved, complexity: 2, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:approvals_left, complexity: 2, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:has_security_reports, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:security_reports_up_to_date_on_target_branch, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:suggested_reviewers) }
end
