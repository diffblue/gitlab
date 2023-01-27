# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LicenseScanning::PackageLicenses, feature_category: :license_compliance do
  let_it_be(:components_to_fetch) do
    [
      Hashie::Mash.new({ name: "beego", purl_type: "golang", version: "v1.10.0" }),
      Hashie::Mash.new({ name: "camelcase", purl_type: "npm", version: "1.2.1" }),
      Hashie::Mash.new({ name: "camelcase", purl_type: "npm", version: "4.1.0" }),
      Hashie::Mash.new({ name: "cliui", purl_type: "npm", version: "2.1.0" }),
      Hashie::Mash.new({ name: "cliui", purl_type: "golang", version: "2.1.0" })
    ]
  end

  before_all do
    create(:pm_package, name: "beego", purl_type: "golang", version: "v1.10.0",
           spdx_identifiers: ["OLDAP-2.1", "OLDAP-2.2"])
    create(:pm_package, name: "camelcase", purl_type: "npm", version: "1.2.1", spdx_identifiers: ["OLDAP-2.1"])
    create(:pm_package, name: "camelcase", purl_type: "npm", version: "4.1.0", spdx_identifiers: ["OLDAP-2.2"])
    create(:pm_package, name: "cliui", purl_type: "npm", version: "2.1.0", spdx_identifiers: ["OLDAP-2.3"])
    create(:pm_package, name: "cliui", purl_type: "golang", version: "2.1.0", spdx_identifiers: ["OLDAP-2.6"])
    create(:pm_package, name: "jst", purl_type: "npm", version: "3.0.2", spdx_identifiers: ["OLDAP-2.4", "OLDAP-2.5"])
    create(:pm_package, name: "jsbn", purl_type: "npm", version: "0.1.1", spdx_identifiers: ["OLDAP-2.4"])
    create(:pm_package, name: "jsdom", purl_type: "npm", version: "11.12.0", spdx_identifiers: ["OLDAP-2.5"])
  end

  subject(:fetch) do
    described_class.new(components: components_to_fetch).fetch
  end

  describe '#fetch' do
    context 'when components to fetch are empty' do
      let_it_be(:components_to_fetch) { [] }

      it { is_expected.to be_empty }
    end

    context 'when components to fetch are not empty' do
      it 'returns only the items that matched the fetched components' do
        expect(fetch).to match_array([
          have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                          licenses: match_array(["OLDAP-2.1", "OLDAP-2.2"])),
          have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1", licenses: ["OLDAP-2.1"]),
          have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0", licenses: ["OLDAP-2.2"]),
          have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0", licenses: ["OLDAP-2.3"]),
          have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0", licenses: ["OLDAP-2.6"])
        ])
      end

      context 'and we change the batch size' do
        before do
          stub_const("Gitlab::LicenseScanning::PackageLicenses::BATCH_SIZE", 1)
        end

        it 'fetches in batches of BATCH_SIZE' do
          control = ActiveRecord::QueryRecorder.new { fetch }

          expect(control.count).to be(components_to_fetch.count)
        end

        it 'still returns only the items that matched the fetched components' do
          expect(fetch).to match_array([
            have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                            licenses: match_array(["OLDAP-2.1", "OLDAP-2.2"])),
            have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1", licenses: ["OLDAP-2.1"]),
            have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0", licenses: ["OLDAP-2.2"]),
            have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0", licenses: ["OLDAP-2.3"]),
            have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0", licenses: ["OLDAP-2.6"])
          ])
        end
      end
    end

    context 'when passing additional components to fetch' do
      let_it_be(:additional_components_to_fetch) do
        [
          Hashie::Mash.new({ name: "jst", purl_type: "npm", version: "3.0.2" }),
          Hashie::Mash.new({ name: "jsbn", purl_type: "npm", version: "0.1.1" }),
          Hashie::Mash.new({ name: "jsdom", purl_type: "npm", version: "11.12.0" })
        ]
      end

      it 'returns all the items that matched the fetched components' do
        fetch = described_class.new(components: components_to_fetch + additional_components_to_fetch).fetch

        expect(fetch).to match_array([
          have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                          licenses: match_array(["OLDAP-2.1", "OLDAP-2.2"])),
          have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1", licenses: ["OLDAP-2.1"]),
          have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0", licenses: ["OLDAP-2.2"]),
          have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0", licenses: ["OLDAP-2.3"]),
          have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0", licenses: ["OLDAP-2.6"]),
          have_attributes(name: "jst", purl_type: "npm", version: "3.0.2",
                          licenses: match_array(["OLDAP-2.4", "OLDAP-2.5"])),
          have_attributes(name: "jsbn", purl_type: "npm", version: "0.1.1", licenses: ["OLDAP-2.4"]),
          have_attributes(name: "jsdom", purl_type: "npm", version: "11.12.0", licenses: ["OLDAP-2.5"])
        ])
      end

      it 'does not execute n+1 queries' do
        control = ActiveRecord::QueryRecorder.new { fetch }

        expect do
          described_class.new(components: components_to_fetch + additional_components_to_fetch).fetch
        end.not_to exceed_query_limit(control)
      end
    end

    context 'when no packages match the given criteria' do
      context 'as the package name does not match' do
        let_it_be(:components_to_fetch) do
          [Hashie::Mash.new({ name: "does-not-match", purl_type: "golang", version: "v1.10.0" })]
        end

        it { is_expected.to be_empty }
      end

      context 'as the package purl_type does not match' do
        let_it_be(:components_to_fetch) do
          [Hashie::Mash.new({ name: "beego", purl_type: "npm", version: "v1.10.0" })]
        end

        it { is_expected.to be_empty }
      end

      context 'as the package version does not match' do
        let_it_be(:components_to_fetch) do
          [Hashie::Mash.new({ name: "beego", purl_type: "golang", version: "does-not-match" })]
        end

        it { is_expected.to be_empty }
      end
    end
  end
end
