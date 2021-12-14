# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['VulnerableKubernetesResource'] do
  it { expect(described_class).to have_graphql_fields(:namespace, :kind, :name, :container_name, :agent, :cluster_id) }
end
