# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanPresenter do
  let(:presenter) { described_class.new(security_scan) }
  let(:security_scan) { build_stubbed(:security_scan, info: { 'errors' => [{ 'type' => 'foo', 'message' => 'bar' }], 'warnings' => [{ 'type' => 'foo', 'message' => 'bar' }] }) }

  describe '#errors' do
    subject { presenter.errors }

    it { is_expected.to match_array(['[foo] bar']) }
  end

  describe '#warnings' do
    subject { presenter.warnings }

    it { is_expected.to match_array(['[foo] bar']) }
  end
end
