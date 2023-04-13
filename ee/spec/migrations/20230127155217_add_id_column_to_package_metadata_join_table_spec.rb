# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddIdColumnToPackageMetadataJoinTable, feature_category: :software_composition_analysis do
  let(:purl_types) { (1..8) }

  context 'when table is up to date' do
    it 'updates the primary key of the table' do
      expect { migrate! }.to change { compound_primary_key? }.from(true).to(false)
    end
  end

  context 'when table is still partitioned' do
    before do
      execute(<<~SQL)
        DROP TABLE pm_package_version_licenses;
        CREATE TABLE pm_package_version_licenses (
          pm_package_version_id bigint NOT NULL,
          pm_license_id bigint NOT NULL,
          purl_type smallint NOT NULL,
          PRIMARY KEY (pm_package_version_id, pm_license_id, purl_type)
        ) PARTITION BY LIST (purl_type);
      SQL

      purl_types.each do |i|
        execute(<<~SQL)
          CREATE TABLE gitlab_partitions_static.pm_package_version_licenses_#{i}
          PARTITION OF pm_package_version_licenses
          FOR VALUES IN (#{i})
        SQL
      end
    end

    it 'unpartitions the table' do
      expect { migrate! }.to change { table_partitioned? }.from(true).to(false)
    end

    it 'updates the primary key of the table' do
      expect { migrate! }.to change { compound_primary_key? }.from(true).to(false)
    end
  end

  def compound_primary_key?
    sql = <<~SQL
      SELECT COUNT(*)
      FROM   pg_index i
      JOIN   pg_attribute a ON a.attrelid = i.indrelid
                           AND a.attnum = ANY(i.indkey)
      WHERE  i.indrelid = 'pm_package_version_licenses'::regclass
      AND    i.indisprimary;
    SQL
    execute(sql).first != 1
  end

  def table_partitioned?
    sql = <<~SQL
      SELECT
        COUNT(*)
      FROM
        pg_partitioned_table
      INNER JOIN pg_class ON pg_class.oid = pg_partitioned_table.partrelid
      WHERE pg_class.relname = 'pm_package_version_licenses'
    SQL
    execute(sql).first != 0
  end

  def execute(sql)
    ApplicationRecord.connection.execute(sql).values.flatten
  end
end
