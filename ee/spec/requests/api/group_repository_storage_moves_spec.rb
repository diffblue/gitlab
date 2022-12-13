# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupRepositoryStorageMoves, feature_category: :gitaly do
  it_behaves_like 'repository_storage_moves API', 'groups' do
    let_it_be(:container) { create(:group, :wiki_repo) }
    let_it_be(:storage_move) { create(:group_repository_storage_move, :scheduled, container: container) }

    let(:repository_storage_move_factory) { :group_repository_storage_move }
    let(:bulk_worker_klass) { Groups::ScheduleBulkRepositoryShardMovesWorker }
  end
end
