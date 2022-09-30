# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timebox do
  let_it_be(:example_class) do
    Class.new(ApplicationRecord) do
      include Timebox

      self.table_name = 'milestones'
    end
  end

  subject(:instance) { example_class.new }

  describe '#to_reference' do
    it 'raises NotImplementedError' do
      expect { subject.to_reference }.to raise_error(NotImplementedError)
    end
  end

  describe '#resource_parent' do
    it 'raises NotImplementedError' do
      expect { subject.resource_parent }.to raise_error(NotImplementedError)
    end
  end

  describe '#merge_requests_enabled?' do
    it 'raises NotImplementedError' do
      expect { subject.merge_requests_enabled? }.to raise_error(NotImplementedError)
    end
  end
end
