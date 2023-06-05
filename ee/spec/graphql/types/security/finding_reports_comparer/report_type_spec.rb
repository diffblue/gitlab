# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComparedSecurityReport'], feature_category: :vulnerability_management do
  let(:expected_fields) { %i[base_report_created_at base_report_out_of_date head_report_created_at added fixed] }

  it { expect(described_class).to have_graphql_fields(expected_fields) }
end
