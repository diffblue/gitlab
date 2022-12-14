# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Geo::HTTPCloneEnabledCheck, feature_category: :geo_replication do
  describe '#check?' do
    subject { described_class.new.check? }

    where(:enabled_protocol, :result) do
      [
        ['unknown', false],
        ['ssh', false],
        ['http', true],
        ['', true],
        [nil, true]
      ]
    end

    with_them do
      before do
        stub_application_setting(enabled_git_access_protocol: enabled_protocol)
      end

      it { is_expected.to eq(result) }
    end
  end
end
