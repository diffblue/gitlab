# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::MigrationObsolete, feature_category: :global_search do
  let(:migration_class) do
    Class.new do
      include Elastic::MigrationObsolete
    end
  end

  subject { migration_class.new }

  describe '#migrate' do
    it 'logs a message and halts the migration' do
      expect(subject).to receive(:log).with(/has been deleted in the last major version upgrade/)
      expect(subject).to receive(:fail_migration_halt_error!).and_return(true)

      subject.migrate
    end
  end

  describe '#completed?' do
    it 'returns false' do
      expect(subject.completed?).to be false
    end
  end

  describe '#obsolete?' do
    it 'returns true' do
      expect(subject.obsolete?).to be true
    end
  end
end
