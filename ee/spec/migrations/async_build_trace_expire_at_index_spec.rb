# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20220224000000_async_build_trace_expire_at_index.rb')

RSpec.describe AsyncBuildTraceExpireAtIndex do
  describe '#up' do
    it 'sets up a delayed concurrent index creation' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:prepare_async_index)
      end

      migrate!
    end
  end

  describe '#down' do
    it 'removes an index' do
      expect_any_instance_of(described_class) do |instance|
        expect(instance).to receive(:unprepare_async_index)
      end

      schema_migrate_down!
    end
  end
end
