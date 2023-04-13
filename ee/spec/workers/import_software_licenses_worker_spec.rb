# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportSoftwareLicensesWorker, feature_category: :software_composition_analysis do
  let(:catalogue) { build(:spdx_catalogue) }
  let(:spdx_apache_license) { build(:spdx_license, :apache_1) }
  let(:spdx_bsd_license) { build(:spdx_license, :bsd) }
  let(:spdx_mit_license) { build(:spdx_license, :mit) }

  describe '#perform' do
    before do
      allow(Gitlab::SPDX::Catalogue).to receive(:latest).and_return(catalogue)
      allow(catalogue).to receive(:each)
        .and_yield(spdx_apache_license)
        .and_yield(spdx_bsd_license)
        .and_yield(spdx_mit_license)
    end

    let!(:apache) { create(:software_license, name: spdx_apache_license.name, spdx_identifier: nil) }
    let!(:mit) { create(:software_license, name: spdx_mit_license.name, spdx_identifier: spdx_mit_license.id) }

    context 'when the licenses.json endpoint is healthy' do
      before do
        subject.perform
      end

      it { expect(apache.reload.spdx_identifier).to eql(spdx_apache_license.id) }
      it { expect(SoftwareLicense.count).to eq(3) }
      it { expect(SoftwareLicense.pluck(:spdx_identifier)).to contain_exactly(spdx_apache_license.id, spdx_mit_license.id, spdx_bsd_license.id) }
      it { expect(SoftwareLicense.pluck(:name)).to contain_exactly(spdx_apache_license.name, spdx_mit_license.name, spdx_bsd_license.name) }

      it 'deletes the software licenses from cache' do
        expect(Rails.cache).to receive(:delete).with(SoftwareLicense::ALL_LICENSE_NAMES_CACHE_KEY)

        subject.perform
      end
    end

    context 'when run multiple times' do
      it 'does not create duplicated software licenses' do
        subject.perform

        expect(SoftwareLicense.count).to eq(3)
        expect { subject.perform }.not_to change(SoftwareLicense, :count)
      end
    end

    context 'when a license has an invalid SPDX identifier' do
      before do
        apache.update_column(:spdx_identifier, 'invalid')
        subject.perform
      end

      it { expect(apache.reload.spdx_identifier).to eql(spdx_apache_license.id) }
      it { expect(SoftwareLicense.pluck(:spdx_identifier)).to contain_exactly(spdx_apache_license.id, spdx_mit_license.id, spdx_bsd_license.id) }
    end

    context 'when a license is deprecated' do
      let!(:gpl) { create(:software_license, name: 'GNU General Public License v1.0 only', spdx_identifier: 'GPL-1.0') }
      let(:spdx_old_gpl_license) { build(:spdx_license, :deprecated_gpl_v1) }
      let(:spdx_new_gpl_license) { build(:spdx_license, :gpl_v1) }

      before do
        allow(catalogue).to receive(:each)
          .and_yield(spdx_new_gpl_license)
          .and_yield(spdx_old_gpl_license)

        subject.perform
      end

      it { expect(gpl.reload.spdx_identifier).to eql('GPL-1.0-only') }
    end
  end
end
