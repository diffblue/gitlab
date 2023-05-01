# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Package, type: :model, feature_category: :package_registry do
  let_it_be(:package) { create(:package) }

  describe '#touch_last_downloaded_at' do
    subject { package.touch_last_downloaded_at }

    context 'when not on a geo secondary' do
      before do
        allow(::Gitlab::Geo).to receive(:secondary?).and_return(false)
      end

      it 'updates the last_downloaded_at column' do
        expect { subject }.to change { package.last_downloaded_at }
      end
    end

    context 'when on a geo secondary' do
      before do
        allow(::Gitlab::Geo).to receive(:secondary?).and_return(true)
      end

      it 'does not update the last_downloaded_at column' do
        expect { subject }.not_to change { package.last_downloaded_at }
      end
    end
  end
end
