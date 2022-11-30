# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Geo::LicenseCheck, feature_category: :geo_replication do
  describe '#check?' do
    using RSpec::Parameterized::TableSyntax

    where(:primary, :geo_enabled, :license_allows, :check_result, :pass_message) do
      true | true | true | true | ''
      true | true | false | false | ''
      true | false | true | true | 'License supports Geo, but Geo is not enabled'
      true | false | false | true | 'License does not support Geo, and Geo is not enabled'
      false | true | true | true | ''
      false | true | false | true | 'License only required on a primary site'
      false | false | true | true | ''
      false | false | false | true | ''
    end

    with_them do
      before do
        allow(Gitlab::Geo).to receive(:primary?).and_return(primary)
        allow(Gitlab::Geo).to receive(:enabled?).and_return(geo_enabled)
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(license_allows)
      end

      it 'checks the license' do
        expect(subject.check?).to eq(check_result)
        expect(described_class.check_pass).to eq(pass_message) if check_result
      end
    end
  end
end
