# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::WithFeatureFlagActors do
  let(:service) do
    Class.new do
      include Gitlab::GitalyClient::WithFeatureFlagActors
    end.new
  end

  describe '#group_actor' do
    context 'when normal project repository' do
      let_it_be(:group) { create(:group, :wiki_repo) }
      let(:expected_project) { nil }
      let(:expected_group) { group }

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { group.wiki.repository }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { group.wiki.repository.raw }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { raw_repo_without_container(group.wiki.repository) }
      end
    end
  end
end
