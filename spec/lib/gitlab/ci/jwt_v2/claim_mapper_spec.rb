# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JwtV2::ClaimMapper, feature_category: :continuous_integration do
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline) }

  let(:source) { :unknown_source }
  let(:url) { 'gitlab.com/gitlab-org/gitlab//.gitlab-ci.yml' }
  let(:project_config) { instance_double(Gitlab::Ci::ProjectConfig, url: url, source: source) }

  subject(:mapper) { described_class.new(project_config, pipeline) }

  it 'returns nil for attributes when source is not implemented' do
    expect(mapper.ci_config_ref_uri).to be_nil
    expect(mapper.ci_config_sha).to be_nil
  end

  context 'when mapper for source is implemented' do
    where(:source) { described_class::MAPPER_FOR_CONFIG_SOURCE.keys }
    let(:ci_config_ref_uri) { 'ci_config_ref_uri' }
    let(:ci_config_sha) { 'ci_config_sha' }

    with_them do
      it 'uses mapper' do
        mapper_class = described_class::MAPPER_FOR_CONFIG_SOURCE[source]
        expect_next_instance_of(mapper_class, project_config, pipeline) do |instance|
          expect(instance).to receive(:ci_config_ref_uri).and_return(ci_config_ref_uri)
          expect(instance).to receive(:ci_config_sha).and_return(ci_config_sha)
        end

        expect(mapper.ci_config_ref_uri).to eq(ci_config_ref_uri)
        expect(mapper.ci_config_sha).to eq(ci_config_sha)
      end
    end
  end
end
