# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LicenseScanning::PackageLicenses, feature_category: :software_composition_analysis do
  let_it_be(:project) { create(:project) }

  let_it_be(:components_to_fetch) do
    [
      Hashie::Mash.new({ name: "beego", purl_type: "golang", version: "v1.10.0", path: nil }),
      Hashie::Mash.new({ name: "camelcase", purl_type: "npm", version: "1.2.1", path: "" }),
      Hashie::Mash.new({ name: "camelcase", purl_type: "npm", version: "4.1.0", path: "package-lock.json" }),
      Hashie::Mash.new({ name: "cliui", purl_type: "npm", version: "2.1.0", path: "package-lock.json" }),
      Hashie::Mash.new({ name: "cliui", purl_type: "golang", version: "2.1.0", path: "package-lock.json" })
    ]
  end

  subject(:fetch) do
    described_class.new(project: project, components: components_to_fetch).fetch
  end

  describe '#fetch' do
    context 'when querying compressed package metadata' do
      before do
        stub_feature_flags(compressed_package_metadata_query: project)
      end

      before_all do
        create(:pm_package, name: "beego", purl_type: "golang",
          other_licenses: [{ license_names: ["OLDAP-2.1", "OLDAP-2.2"], versions: ["v1.10.0"] }])
        create(:pm_package, name: "camelcase", purl_type: "npm", other_licenses: [
          { license_names: ["OLDAP-2.1"], versions: ["1.2.1"] },
          { license_names: ["OLDAP-2.2"], versions: ["4.1.0"] }
        ])

        create(:pm_package, name: "cliui", purl_type: "npm",
          other_licenses: [{ license_names: ["OLDAP-2.3"], versions: ["2.1.0"] }])

        create(:pm_package, name: "cliui", purl_type: "golang",
          other_licenses: [{ license_names: ["OLDAP-2.6"], versions: ["2.1.0"] }])

        create(:pm_package, name: "jst", purl_type: "npm",
          other_licenses: [{ license_names: ["OLDAP-2.4", "OLDAP-2.5"], versions: ["3.0.2"] }])

        create(:pm_package, name: "jsbn", purl_type: "npm",
          other_licenses: [{ license_names: ["OLDAP-2.4"], versions: ["0.1.1"] }])

        create(:pm_package, name: "jsdom", purl_type: "npm",
          other_licenses: [{ license_names: ["OLDAP-2.5"], versions: ["11.12.0"] }])
      end

      context 'and components to fetch are empty' do
        let_it_be(:components_to_fetch) { [] }

        it { is_expected.to be_empty }
      end

      context 'and components to fetch are not empty' do
        it 'returns only the items that matched the fetched components' do
          expect(fetch).to contain_exactly(
            have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0", path: "",
              licenses: contain_exactly(
                { name: "Open LDAP Public License v2.1", spdx_identifier: "OLDAP-2.1" },
                { name: "Open LDAP Public License v2.2", spdx_identifier: "OLDAP-2.2" })),
            have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1", path: "",
              licenses: [{ "name" => "Open LDAP Public License v2.1", "spdx_identifier" => "OLDAP-2.1" }]),
            have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0", path: "package-lock.json",
              licenses: [{ "name" => "Open LDAP Public License v2.2", "spdx_identifier" => "OLDAP-2.2" }]),
            have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0", path: "package-lock.json",
              licenses: [{ "name" => "Open LDAP Public License v2.3", "spdx_identifier" => "OLDAP-2.3" }]),
            have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0", path: "package-lock.json",
              licenses: [{ "name" => "Open LDAP Public License v2.6", "spdx_identifier" => "OLDAP-2.6" }])
          )
        end

        context 'and components to fetch contains entries that do not have licenses' do
          let_it_be(:components_to_fetch) do
            [
              Hashie::Mash.new({ name: "beego", purl_type: "golang", version: "v1.10.0" }),
              Hashie::Mash.new({ name: "package1-without-license", purl_type: "npm", version: "1.2.1" }),
              Hashie::Mash.new({ name: "camelcase", purl_type: "npm", version: "4.1.0" }),
              Hashie::Mash.new({ name: "package2-without-license", purl_type: "npm", version: "2.1.0" }),
              Hashie::Mash.new({ name: "cliui", purl_type: "golang", version: "2.1.0" }),
              Hashie::Mash.new({ name: "package3-without-license", purl_type: "golang", version: "2.1.0" })
            ]
          end

          it 'returns elements in the same order as the components to fetch' do
            expect(fetch).to match([
              have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                              licenses: contain_exactly(
                                { name: "Open LDAP Public License v2.1", spdx_identifier: "OLDAP-2.1" },
                                { name: "Open LDAP Public License v2.2", spdx_identifier: "OLDAP-2.2" })),
              have_attributes(name: "package1-without-license", purl_type: "npm", version: "1.2.1",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.2", "spdx_identifier" => "OLDAP-2.2" }]),
              have_attributes(name: "package2-without-license", purl_type: "npm", version: "2.1.0",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.6", "spdx_identifier" => "OLDAP-2.6" }]),
              have_attributes(name: "package3-without-license", purl_type: "golang", version: "2.1.0",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }])
            ])
          end
        end

        context 'and we change the batch size' do
          before do
            stub_const("Gitlab::LicenseScanning::PackageLicenses::BATCH_SIZE", 1)
          end

          it 'executes 1 query for each batch' do
            number_of_queries_per_batch = 1
            control = ActiveRecord::QueryRecorder.new(skip_cached: false) { fetch }
            expect(control.count).to be(components_to_fetch.count * number_of_queries_per_batch)
          end

          it 'does not query more than BATCH_SIZE component tuples at a time' do
            query_with_a_single_component_tuple = /IN \(([^,]+), '[^']+'\)\)/i

            original = PackageMetadata::Package.method(:where)
            expect(PackageMetadata::Package).to receive(:where) do |args|
              expect(args.to_sql).to match(query_with_a_single_component_tuple)
              original.call(args)
            end.at_least(:once)

            fetch
          end

          it 'still returns only the items that matched the fetched components' do
            expect(fetch).to contain_exactly(
              have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                              licenses: contain_exactly(
                                { name: "Open LDAP Public License v2.1", spdx_identifier: "OLDAP-2.1" },
                                { name: "Open LDAP Public License v2.2", spdx_identifier: "OLDAP-2.2" })),
              have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1",
                licenses: [{ "name" => "Open LDAP Public License v2.1", "spdx_identifier" => "OLDAP-2.1" }]),
              have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.2", "spdx_identifier" => "OLDAP-2.2" }]),
              have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.3", "spdx_identifier" => "OLDAP-2.3" }]),
              have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.6", "spdx_identifier" => "OLDAP-2.6" }])
            )
          end
        end

        context 'with load balancing enabled', :db_load_balancing do
          it 'uses the replica' do
            expect(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_replicas_for_read_queries)
              .and_call_original

            fetch
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
            fetch = described_class.new(project: project,
              components: components_to_fetch + additional_components_to_fetch).fetch

            expect(fetch).to contain_exactly(
              have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                              licenses: contain_exactly(
                                { name: "Open LDAP Public License v2.1", spdx_identifier: "OLDAP-2.1" },
                                { name: "Open LDAP Public License v2.2", spdx_identifier: "OLDAP-2.2" })),
              have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1",
                licenses: [{ "name" => "Open LDAP Public License v2.1", "spdx_identifier" => "OLDAP-2.1" }]),
              have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.2", "spdx_identifier" => "OLDAP-2.2" }]),
              have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.3", "spdx_identifier" => "OLDAP-2.3" }]),
              have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.6", "spdx_identifier" => "OLDAP-2.6" }]),
              have_attributes(name: "jst", purl_type: "npm", version: "3.0.2",
                              licenses: contain_exactly(
                                { name: "Open LDAP Public License v2.4", spdx_identifier: "OLDAP-2.4" },
                                { name: "Open LDAP Public License v2.5", spdx_identifier: "OLDAP-2.5" })),
              have_attributes(name: "jsbn", purl_type: "npm", version: "0.1.1",
                licenses: [{ "name" => "Open LDAP Public License v2.4", "spdx_identifier" => "OLDAP-2.4" }]),
              have_attributes(name: "jsdom", purl_type: "npm", version: "11.12.0",
                licenses: [{ "name" => "Open LDAP Public License v2.5", "spdx_identifier" => "OLDAP-2.5" }])
            )
          end

          it 'does not execute n+1 queries' do
            control = ActiveRecord::QueryRecorder.new { fetch }

            expect do
              described_class.new(project: project,
                components: components_to_fetch + additional_components_to_fetch).fetch
            end.not_to exceed_query_limit(control)
          end
        end

        context 'when component is missing attributes' do
          let_it_be(:components_to_fetch) do
            [
              Hashie::Mash.new({ name: "jstom", version: "11.12.0" }),
              Hashie::Mash.new({ version: "11.12.0", purl_type: "npm" }),
              Hashie::Mash.new({})
            ]
          end

          it 'returns "unknown" license for all the matching components' do
            expect(fetch).to contain_exactly(
              have_attributes(name: "jstom", purl_type: nil, version: "11.12.0",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: nil, purl_type: "npm", version: "11.12.0",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: nil, purl_type: nil, version: nil,
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }])
            )
          end
        end

        context 'when packages contain nil or empty licenses' do
          before_all do
            create(:pm_package, name: 'pg', purl_type: 'gem', licenses: nil)
            create(:pm_package, name: 'JUnit', purl_type: 'maven', licenses: [])
          end

          let_it_be(:components_to_fetch) do
            [
              Hashie::Mash.new({ name: 'pg', purl_type: 'gem', version: '1.2.3' }),
              Hashie::Mash.new({ name: 'JUnit', purl_type: 'maven', version: '4.5.6' })
            ]
          end

          it 'returns "unknown" license for all the matching components' do
            expect(fetch).to contain_exactly(
              have_attributes(name: "pg", purl_type: "gem", version: "1.2.3",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: "JUnit", purl_type: "maven", version: "4.5.6",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }])
            )
          end
        end

        context 'when no packages match the given criteria' do
          using RSpec::Parameterized::TableSyntax

          where(:case_name, :name, :purl_type, :version) do
            "name does not match"      | "does-not-match" | "golang" | "v1.10.0"
            "purl_type does not match" | "beego"          | "npm"    | "v1.10.0"
            # TODO: re-enable the following when https://gitlab.com/gitlab-org/vulnerability-research/foss/semver_dialects/-/issues/3
            # has been completed.
            # "version is invalid"     | "beego"          | "golang" | "invalid-version"
          end

          with_them do
            let(:components_to_fetch) { [Hashie::Mash.new({ name: name, purl_type: purl_type, version: version })] }

            it "returns 'unknown' as the license" do
              expect(fetch).to eq([
                "name" => name, "purl_type" => purl_type, "version" => version,
                "licenses" => [{ "name" => "unknown", "spdx_identifier" => "unknown" }]
              ])
            end
          end

          context 'and the version is invalid' do
            let(:components_to_fetch) do
              [Hashie::Mash.new({ name: "beego", purl_type: "golang", version: "invalid-version" })]
            end

            # this test shows that the current matching behaviour is incorrect, because the default
            # license is returned, when 'unknown' should actually be returned.
            # We need to add a new `valid?` method to the semver_dialects gem to handle invalid versions.
            #
            # See https://gitlab.com/gitlab-org/vulnerability-research/foss/semver_dialects/-/issues/3
            # for more details.
            #
            # TODO: once we have a `valid?` method in the semver_dialects gem, remove this test
            # and add a test to the table in the `returns 'unknown' as the license` example above.
            it "returns the default licenses" do
              expect(fetch).to eq([
                "name" => "beego", "purl_type" => "golang", "version" => "invalid-version", "path" => "",
                "licenses" => [{ "name" => "Default License 2.1", "spdx_identifier" => "DEFAULT-2.1" }]
              ])
            end
          end

          context 'and the version does not match' do
            let(:components_to_fetch) do
              [Hashie::Mash.new({ name: "beego", purl_type: "golang", version: "123.456.789" })]
            end

            it "returns the default licenses" do
              expect(fetch).to eq([
                "name" => "beego", "purl_type" => "golang", "version" => "123.456.789", "path" => "",
                "licenses" => [{ "name" => "Default License 2.1", "spdx_identifier" => "DEFAULT-2.1" }]
              ])
            end
          end
        end

        context 'when software license is not present for a given spdx identifier' do
          before do
            create(:software_license, :user_entered, spdx_identifier: 'CUSTOM-0.1')
            create(:pm_package, name: "beego_custom",
               purl_type: "golang",
               other_licenses: [{ license_names: ['CUSTOM-0.1'], versions: ["v1.10.0"] }])
          end

          let_it_be(:components_to_fetch) do
            [
              Hashie::Mash.new({ name: "beego_custom", purl_type: "golang", version: "v1.10.0" })
            ]
          end

          it 'returns spdx identifier instead of license name' do
            expect(fetch).to contain_exactly(
              have_attributes(name: 'beego_custom', purl_type: 'golang', version: 'v1.10.0',
                licenses: [{ "name" => "CUSTOM-0.1", "spdx_identifier" => "CUSTOM-0.1" }])
            )
          end
        end
      end
    end

    context 'when querying uncompressed package metadata' do
      before do
        stub_feature_flags(compressed_package_metadata_query: false)
      end

      before_all do
        create(:pm_package_version_license, :with_all_relations, name: "beego",
               purl_type: "golang", version: "v1.10.0", license_name: "OLDAP-2.1")
        create(:pm_package_version_license, :with_all_relations, name: "beego",
               purl_type: "golang", version: "v1.10.0", license_name: "OLDAP-2.2")
        create(:pm_package_version_license, :with_all_relations, name: "camelcase",
               purl_type: "npm", version: "1.2.1", license_name: "OLDAP-2.1")
        create(:pm_package_version_license, :with_all_relations, name: "camelcase",
               purl_type: "npm", version: "4.1.0", license_name: "OLDAP-2.2")
        create(:pm_package_version_license, :with_all_relations, name: "cliui",
               purl_type: "npm", version: "2.1.0", license_name: "OLDAP-2.3")
        create(:pm_package_version_license, :with_all_relations, name: "cliui",
               purl_type: "golang", version: "2.1.0", license_name: "OLDAP-2.6")
        create(:pm_package_version_license, :with_all_relations, name: "jst",
               purl_type: "npm", version: "3.0.2", license_name: "OLDAP-2.4")
        create(:pm_package_version_license, :with_all_relations, name: "jst",
               purl_type: "npm", version: "3.0.2", license_name: "OLDAP-2.5")
        create(:pm_package_version_license, :with_all_relations, name: "jsbn",
               purl_type: "npm", version: "0.1.1", license_name: "OLDAP-2.4")
        create(:pm_package_version_license, :with_all_relations, name: "jsdom",
               purl_type: "npm", version: "11.12.0", license_name: "OLDAP-2.5")
      end

      context 'and components to fetch are empty' do
        let_it_be(:components_to_fetch) { [] }

        it { is_expected.to be_empty }
      end

      context 'and components to fetch are not empty' do
        it 'returns only the items that matched the fetched components' do
          expect(fetch).to contain_exactly(
            have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0", path: "",
              licenses: contain_exactly(
                { name: "Open LDAP Public License v2.1", spdx_identifier: "OLDAP-2.1" },
                { name: "Open LDAP Public License v2.2", spdx_identifier: "OLDAP-2.2" })),
            have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1", path: "",
              licenses: [{ "name" => "Open LDAP Public License v2.1", "spdx_identifier" => "OLDAP-2.1" }]),
            have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0", path: "package-lock.json",
              licenses: [{ "name" => "Open LDAP Public License v2.2", "spdx_identifier" => "OLDAP-2.2" }]),
            have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0", path: "package-lock.json",
              licenses: [{ "name" => "Open LDAP Public License v2.3", "spdx_identifier" => "OLDAP-2.3" }]),
            have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0", path: "package-lock.json",
              licenses: [{ "name" => "Open LDAP Public License v2.6", "spdx_identifier" => "OLDAP-2.6" }])
          )
        end

        context 'and components to fetch contains entries that do not have licenses' do
          let_it_be(:components_to_fetch) do
            [
              Hashie::Mash.new({ name: "beego", purl_type: "golang", version: "v1.10.0" }),
              Hashie::Mash.new({ name: "package1-without-license", purl_type: "npm", version: "1.2.1" }),
              Hashie::Mash.new({ name: "camelcase", purl_type: "npm", version: "4.1.0" }),
              Hashie::Mash.new({ name: "package2-without-license", purl_type: "npm", version: "2.1.0" }),
              Hashie::Mash.new({ name: "cliui", purl_type: "golang", version: "2.1.0" }),
              Hashie::Mash.new({ name: "package3-without-license", purl_type: "golang", version: "2.1.0" })
            ]
          end

          it 'returns elements in the same order as the components to fetch' do
            expect(fetch).to match([
              have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                              licenses: contain_exactly(
                                { name: "Open LDAP Public License v2.1", spdx_identifier: "OLDAP-2.1" },
                                { name: "Open LDAP Public License v2.2", spdx_identifier: "OLDAP-2.2" })),
              have_attributes(name: "package1-without-license", purl_type: "npm", version: "1.2.1",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.2", "spdx_identifier" => "OLDAP-2.2" }]),
              have_attributes(name: "package2-without-license", purl_type: "npm", version: "2.1.0",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.6", "spdx_identifier" => "OLDAP-2.6" }]),
              have_attributes(name: "package3-without-license", purl_type: "golang", version: "2.1.0",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }])
            ])
          end
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
            expect(fetch).to contain_exactly(
              have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                              licenses: contain_exactly(
                                { name: "Open LDAP Public License v2.1", spdx_identifier: "OLDAP-2.1" },
                                { name: "Open LDAP Public License v2.2", spdx_identifier: "OLDAP-2.2" })),
              have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1",
                licenses: [{ "name" => "Open LDAP Public License v2.1", "spdx_identifier" => "OLDAP-2.1" }]),
              have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.2", "spdx_identifier" => "OLDAP-2.2" }]),
              have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.3", "spdx_identifier" => "OLDAP-2.3" }]),
              have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.6", "spdx_identifier" => "OLDAP-2.6" }])
            )
          end
        end

        context 'with load balancing enabled', :db_load_balancing do
          it 'uses the replica' do
            expect(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_replicas_for_read_queries)
              .and_call_original

            fetch
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
            fetch = described_class.new(project: project,
              components: components_to_fetch + additional_components_to_fetch).fetch

            expect(fetch).to contain_exactly(
              have_attributes(name: "beego", purl_type: "golang", version: "v1.10.0",
                              licenses: contain_exactly(
                                { name: "Open LDAP Public License v2.1", spdx_identifier: "OLDAP-2.1" },
                                { name: "Open LDAP Public License v2.2", spdx_identifier: "OLDAP-2.2" })),
              have_attributes(name: "camelcase", purl_type: "npm", version: "1.2.1",
                licenses: [{ "name" => "Open LDAP Public License v2.1", "spdx_identifier" => "OLDAP-2.1" }]),
              have_attributes(name: "camelcase", purl_type: "npm", version: "4.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.2", "spdx_identifier" => "OLDAP-2.2" }]),
              have_attributes(name: "cliui", purl_type: "npm", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.3", "spdx_identifier" => "OLDAP-2.3" }]),
              have_attributes(name: "cliui", purl_type: "golang", version: "2.1.0",
                licenses: [{ "name" => "Open LDAP Public License v2.6", "spdx_identifier" => "OLDAP-2.6" }]),
              have_attributes(name: "jst", purl_type: "npm", version: "3.0.2",
                              licenses: contain_exactly(
                                { name: "Open LDAP Public License v2.4", spdx_identifier: "OLDAP-2.4" },
                                { name: "Open LDAP Public License v2.5", spdx_identifier: "OLDAP-2.5" })),
              have_attributes(name: "jsbn", purl_type: "npm", version: "0.1.1",
                licenses: [{ "name" => "Open LDAP Public License v2.4", "spdx_identifier" => "OLDAP-2.4" }]),
              have_attributes(name: "jsdom", purl_type: "npm", version: "11.12.0",
                licenses: [{ "name" => "Open LDAP Public License v2.5", "spdx_identifier" => "OLDAP-2.5" }])
            )
          end

          it 'does not execute n+1 queries' do
            control = ActiveRecord::QueryRecorder.new { fetch }

            expect do
              described_class.new(project: project,
                components: components_to_fetch + additional_components_to_fetch).fetch
            end.not_to exceed_query_limit(control)
          end
        end

        context 'when component is missing attributes' do
          let_it_be(:components_to_fetch) do
            [
              Hashie::Mash.new({ name: "jstom", version: "11.12.0" }),
              Hashie::Mash.new({ version: "11.12.0", purl_type: "npm" }),
              Hashie::Mash.new({})
            ]
          end

          it 'returns all the items that matched the fetched components with unknown licenses' do
            expect(fetch).to contain_exactly(
              have_attributes(name: "jstom", purl_type: nil, version: "11.12.0",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: nil, purl_type: "npm", version: "11.12.0",
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }]),
              have_attributes(name: nil, purl_type: nil, version: nil,
                licenses: [{ "name" => "unknown", "spdx_identifier" => "unknown" }])
            )
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
              expect(fetch).to eq([
                "name" => name, "purl_type" => purl_type, "version" => version,
                "licenses" => [{ "name" => "unknown", "spdx_identifier" => "unknown" }]
              ])
            end
          end
        end

        context 'when software license is not present for a given spdx identifier' do
          before do
            create(:software_license, :user_entered, spdx_identifier: 'CUSTOM-0.1')
            create(:pm_package_version_license, :with_all_relations, name: "beego_custom",
                   purl_type: "golang", version: "v1.10.0", license_name: "CUSTOM-0.1")
          end

          let_it_be(:components_to_fetch) do
            [
              Hashie::Mash.new({ name: "beego_custom", purl_type: "golang", version: "v1.10.0" })
            ]
          end

          it 'returns spdx identifier instead of license name' do
            expect(fetch).to contain_exactly(
              have_attributes(name: 'beego_custom', purl_type: 'golang', version: 'v1.10.0',
                licenses: [{ "name" => "CUSTOM-0.1", "spdx_identifier" => "CUSTOM-0.1" }])
            )
          end
        end
      end
    end
  end
end
