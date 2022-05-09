# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NetworkPolicy'] do
  it { expect(described_class.graphql_name).to eq('NetworkPolicy') }

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(
      :name,
      :kind,
      :namespace,
      :enabled,
      :from_auto_devops,
      :yaml,
      :updated_at,
      :environments
    )
  end
end
