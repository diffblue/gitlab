# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::AttachmentLegacyRegistryFinder, :geo do
  before do
    stub_feature_flags(geo_upload_replication: false )
  end

  it_behaves_like 'a file registry finder' do
    let_it_be(:project) { create(:project) }

    let_it_be(:replicable_1) { create(:upload, model: project) }
    let_it_be(:replicable_2) { create(:upload, model: project) }
    let_it_be(:replicable_3) { create(:upload, :issuable_upload, model: project) }
    let_it_be(:replicable_4) { create(:upload, model: project) }
    let_it_be(:replicable_5) { create(:upload, model: project) }
    let_it_be(:replicable_6) { create(:upload, :personal_snippet_upload) }
    let_it_be(:replicable_7) { create(:upload, :object_storage, model: project) }
    let_it_be(:replicable_8) { create(:upload, :object_storage, model: project) }
    let_it_be(:replicable_9) { create(:upload, :object_storage, model: project) }

    let_it_be(:registry_1) { create(:geo_upload_legacy_registry, :attachment, :failed, file_id: replicable_1.id) }
    let_it_be(:registry_2) { create(:geo_upload_legacy_registry, :attachment, file_id: replicable_2.id, missing_on_primary: true) }
    let_it_be(:registry_3) { create(:geo_upload_legacy_registry, :attachment, :never_synced, file_id: replicable_3.id) }
    let_it_be(:registry_4) { create(:geo_upload_legacy_registry, :attachment, :failed, file_id: replicable_4.id) }
    let_it_be(:registry_5) { create(:geo_upload_legacy_registry, :attachment, file_id: replicable_5.id, missing_on_primary: true, retry_at: 1.day.ago) }
    let_it_be(:registry_6) { create(:geo_upload_legacy_registry, :attachment, :failed, file_id: replicable_6.id) }
    let_it_be(:registry_7) { create(:geo_upload_legacy_registry, :attachment, :failed, file_id: replicable_7.id, missing_on_primary: true) }
    let_it_be(:registry_8) { create(:geo_upload_legacy_registry, :attachment, :never_synced, file_id: replicable_8.id) }
  end
end
