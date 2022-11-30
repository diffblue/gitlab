# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MirrorConfiguration do
  let(:klazz) { Class.new { include MirrorConfiguration } }

  subject(:instance) { klazz.new }

  describe '#only_mirror_protected_branches_column?' do
    it 'raises NotImplementedError' do
      expect { subject.only_mirror_protected_branches_column }.to raise_error(NotImplementedError)
    end
  end
end
