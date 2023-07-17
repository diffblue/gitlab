# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::StopSignal, feature_category: :software_composition_analysis do
  describe '#stop?' do
    using RSpec::Parameterized::TableSyntax

    subject(:stop?) { described_class.new(lease, 10.seconds, 5.seconds).stop? }

    where(:ttl, :should_stop?) do
      6   | false
      5   | false
      4   | true
      nil | true
    end

    with_them do
      let(:lease) { instance_double(Gitlab::ExclusiveLease, ttl: ttl) }

      it { is_expected.to eq(should_stop?) }
    end
  end
end
