# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ScheduleBulkRepositoryShardMovesWorker, feature_category: :gitaly do
  it_behaves_like 'schedules bulk repository shard moves' do
    let_it_be_with_reload(:container) { create(:group, :wiki_repo) }

    let(:move_service_klass) { Groups::RepositoryStorageMove }
    let(:worker_klass) { Groups::UpdateRepositoryStorageWorker }
  end
end
