# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportHelper do
  describe '#group_export_descriptions' do
    it 'includes EE features in the description' do
      expect(helper.group_export_descriptions).to include('Epics', 'Events', 'Group wikis')
    end
  end
end
