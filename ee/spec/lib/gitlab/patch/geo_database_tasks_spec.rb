# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::GeoDatabaseTasks do
  subject do
    Class.new do
      prepend Gitlab::Patch::GeoDatabaseTasks

      def dump_filename(db_config_name, format = ApplicationRecord.schema_format)
        'foo.sql'
      end

      def cache_dump_filename(db_config_name, format = ApplicationRecord.schema_format)
        'bar.yml'
      end
    end.new
  end

  describe '#dump_filename' do
    context 'with geo database config name' do
      it 'returns the path for the structure.sql file in the Geo database dir' do
        expect(subject.dump_filename(:geo)).to eq Rails.root.join('ee/db/geo/structure.sql').to_s
      end
    end

    context 'with other database config name' do
      it 'calls super' do
        expect(subject.dump_filename(:main)).to eq 'foo.sql'
      end
    end
  end

  describe '#cache_dump_filename' do
    context 'with geo database config name' do
      it 'returns the path for the schema_cache file in the Geo database dir' do
        expect(subject.cache_dump_filename(:geo)).to eq Rails.root.join('ee/db/geo/schema_cache.yml').to_s
      end
    end

    context 'with other database config name' do
      it 'calls super' do
        expect(subject.cache_dump_filename(:main)).to eq 'bar.yml'
      end
    end
  end
end
