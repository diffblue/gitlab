# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AuditEventStreamingHeader'] do
  let(:fields) do
    %i[id key value]
  end

  specify { expect(described_class.graphql_name).to eq('AuditEventStreamingHeader') }
  specify { expect(described_class).to have_graphql_fields(fields) }
end
