# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::PurgeScansService, feature_category: :vulnerability_management do
  describe 'class interface' do
    describe '.purge_stale_records' do
      let(:stale_scan) { create(:security_scan, created_at: 91.days.ago) }
      let(:fresh_scan) { create(:security_scan) }

      subject(:purge_stale_records) { described_class.purge_stale_records }

      it 'instantiates the service class with stale scans' do
        expect { purge_stale_records }.to change { stale_scan.reload.status }.to("purged")
                                      .and not_change { fresh_scan.reload.status }
      end
    end

    describe '.purge_by_build_ids' do
      let(:security_scans) { create_list(:security_scan, 2) }

      subject(:purge_by_build_ids) { described_class.purge_by_build_ids([security_scans.first.build_id]) }

      it 'instantiates the service class with scans by given build ids' do
        expect { purge_by_build_ids }.to change { security_scans.first.reload.status }.to("purged")
                                     .and not_change { security_scans.second.reload.status }
      end
    end
  end
end
