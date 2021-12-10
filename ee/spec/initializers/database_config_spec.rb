# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database config initializer for GitLab EE', :reestablished_active_record_base do
  subject do
    load Rails.root.join('config/initializers/database_config.rb')
  end

  let(:max_threads) { 8 }

  before do
    allow(Gitlab::Runtime).to receive(:max_threads).and_return(max_threads)
  end

  context "and the runtime is Sidekiq" do
    before do
      allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
    end

    context 'when no custom headroom is specified' do
      it 'sets the pool size based on the number of worker threads' do
        old = Geo::TrackingBase.connection_db_config.pool

        expect(old).not_to eq(18)

        expect { subject }
          .to change { Geo::TrackingBase.connection_db_config.pool }
          .from(old)
          .to(18)
      end
    end

    context "when specifying headroom through an ENV variable" do
      let(:headroom) { 15 }

      before do
        stub_env("DB_POOL_HEADROOM", headroom)
      end

      it "adds headroom on top of the calculated size" do
        old = Geo::TrackingBase.connection_db_config.pool

        expect { subject }
          .to change { Geo::TrackingBase.connection_db_config.pool }
          .from(old)
          .to(23)
      end
    end
  end
end
