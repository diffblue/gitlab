# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Geo::DesignRegistryFinder, :geo, feature_category: :geo_replication do
  it_behaves_like 'a registry finder' do
    before do
      stub_registry_replication_config(enabled: true)
    end

    let_it_be(:group) { create(:group) }

    let_it_be(:replicable_1) { create(:project, group: group) }
    let_it_be(:replicable_2) { create(:project, group: group) }
    let_it_be(:replicable_3) { create(:project, group: group) }
    let_it_be(:replicable_4) { create(:project, group: group) }
    let_it_be(:replicable_5) { create(:project, group: group) }
    let_it_be(:replicable_6) { create(:project, group: group) }
    let_it_be(:replicable_7) { create(:project, group: group) }
    let_it_be(:replicable_8) { create(:project, group: group) }

    let_it_be(:registry_1) { create(:geo_design_registry, :sync_failed, project_id: replicable_1.id) }
    let_it_be(:registry_2) { create(:geo_design_registry, :synced, project_id: replicable_2.id) }
    let_it_be(:registry_3) { create(:geo_design_registry, project_id: replicable_3.id) }
    let_it_be(:registry_4) { create(:geo_design_registry, :sync_failed, project_id: replicable_4.id) }
    let_it_be(:registry_5) { create(:geo_design_registry, :synced, project_id: replicable_5.id) }
    let_it_be(:registry_6) { create(:geo_design_registry, :sync_failed, project_id: replicable_6.id) }
    let_it_be(:registry_7) { create(:geo_design_registry, :sync_failed, project_id: replicable_7.id) }
    let_it_be(:registry_8) { create(:geo_design_registry, project_id: replicable_8.id) }
  end
end
