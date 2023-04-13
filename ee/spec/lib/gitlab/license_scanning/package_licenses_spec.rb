# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LicenseScanning::PackageLicenses, feature_category: :software_composition_analysis do
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
    create(:pm_package_version_license, :with_all_relations, name: "beego", purl_type: "golang", version: "v1.10.0",
           license_name: "OLDAP-2.1")
    create(:pm_package_version_license, :with_all_relations, name: "beego", purl_type: "golang", version: "v1.10.0",
           license_name: "OLDAP-2.2")
    create(:pm_package_version_license, :with_all_relations, name: "camelcase", purl_type: "npm", version: "1.2.1",
           license_name: "OLDAP-2.1")
    create(:pm_package_version_license, :with_all_relations, name: "camelcase", purl_type: "npm", version: "4.1.0",
           license_name: "OLDAP-2.2")
    create(:pm_package_version_license, :with_all_relations, name: "cliui", purl_type: "npm", version: "2.1.0",
           license_name: "OLDAP-2.3")
    create(:pm_package_version_license, :with_all_relations, name: "cliui", purl_type: "golang", version: "2.1.0",
           license_name: "OLDAP-2.6")
    create(:pm_package_version_license, :with_all_relations, name: "jst", purl_type: "npm", version: "3.0.2",
           license_name: "OLDAP-2.4")
    create(:pm_package_version_license, :with_all_relations, name: "jst", purl_type: "npm", version: "3.0.2",
           license_name: "OLDAP-2.5")
    create(:pm_package_version_license, :with_all_relations, name: "jsbn", purl_type: "npm", version: "0.1.1",
           license_name: "OLDAP-2.4")
    create(:pm_package_version_license, :with_all_relations, name: "jsdom", purl_type: "npm", version: "11.12.0",
           license_name: "OLDAP-2.5")
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

        it 'executes 2 queries for each batch' do
          number_of_queries_per_batch = 2
          control = ActiveRecord::QueryRecorder.new { fetch }

          expect(control.count).to be(components_to_fetch.count * number_of_queries_per_batch)
        end

        it 'does not query more than BATCH_SIZE component tuples at a time' do
          query_with_a_single_component_tuple = /\(VALUES \(([^,]+), '([^']+)', '[^']+'\)\) SELECT DISTINCT/i
          expect(ApplicationRecord.connection).to receive(:execute)
            .with(query_with_a_single_component_tuple).at_least(:once).and_call_original

          fetch
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

      context 'with load balancing enabled', :db_load_balancing do
        it 'uses the replica' do
          expect(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_replicas_for_read_queries)
            .and_call_original

          fetch
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

    context 'when component lacks of attributes' do
      let_it_be(:components_to_fetch) do
        [
          Hashie::Mash.new({ name: "jstom", version: "11.12.0" }),
          Hashie::Mash.new({ version: "11.12.0", purl_type: "npm" }),
          Hashie::Mash.new({})
        ]
      end

      it 'returns all the items that matched the fetched components with unknown licenses' do
        expect(fetch).to match_array([
          have_attributes(name: "jstom", purl_type: nil, version: "11.12.0", licenses: ["unknown"]),
          have_attributes(name: nil, purl_type: "npm", version: "11.12.0", licenses: ["unknown"]),
          have_attributes(name: nil, purl_type: nil, version: nil, licenses: ["unknown"])
        ])
      end
    end

    context 'when no packages match the given criteria' do
      using RSpec::Parameterized::TableSyntax

      where(:case_name, :name, :purl_type, :version) do
        "name does not match"      | "does-not-match" | "golang" | "v1.10.0"
        "purl_type does not match" | "beego"          | "npm"    | "v1.10.0"
        "version does not match"   | "beego"          | "golang" | "does-not-match"
      end

      with_them do
        let(:components_to_fetch) { [Hashie::Mash.new({ name: name, purl_type: purl_type, version: version })] }

        it "returns 'unknown' as the license" do
          expect(fetch).to match_array([
            have_attributes(name: name, purl_type: purl_type, version: version, licenses: match_array(["unknown"]))
          ])
        end
      end
    end
  end
end
