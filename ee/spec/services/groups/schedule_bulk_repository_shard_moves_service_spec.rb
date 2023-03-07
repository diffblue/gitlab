# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ScheduleBulkRepositoryShardMovesService, feature_category: :subgroups do
  it_behaves_like 'moves repository shard in bulk' do
    let_it_be_with_reload(:container) { create(:group, :wiki_repo) }

    let(:move_service_klass) { Groups::RepositoryStorageMove }
    let(:bulk_worker_klass) { Groups::ScheduleBulkRepositoryShardMovesWorker }
  end
end
