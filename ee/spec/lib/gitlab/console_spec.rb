# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Console, feature_category: :application_instrumentation do
  describe '.welcome!' do
    context 'when running in the Rails console' do
      before do
        allow(Gitlab::Runtime).to receive(:console?).and_return(true)
        allow(Gitlab::Geo).to receive(:enabled?).and_return(true)
        allow(Gitlab::Metrics::BootTimeTracker.instance).to receive(:startup_time).and_return(42)
      end

      it 'prints a welcome message' do
        expect($stdout).to receive(:puts).ordered.with(include("--"))
        expect($stdout).to receive(:puts).ordered.with(include("Ruby:"))
        expect($stdout).to receive(:puts).ordered.with(include("GitLab:"))
        expect($stdout).to receive(:puts).ordered.with(include("GitLab Shell:"))
        expect($stdout).to receive(:puts).ordered.with(include("PostgreSQL:"))
        expect($stdout).to receive(:puts).ordered.with(include("Geo enabled:"))
        expect($stdout).to receive(:puts).ordered.with(include("Geo server:"))
        expect($stdout).to receive(:puts).ordered.with(include("--"))
        expect($stdout).not_to receive(:puts).ordered

        described_class.welcome!
      end
    end
  end
end
