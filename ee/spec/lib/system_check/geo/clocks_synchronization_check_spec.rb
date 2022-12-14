# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Geo::ClocksSynchronizationCheck, :silence_stdout, feature_category: :geo_replication do
  let(:ntp_host_env) { 'ntp.ubuntu.com' }
  let(:ntp_port_env) { '123' }
  let(:ntp_timeout_env) { '30' }

  context 'with default accessor values' do
    describe '#ntp_host' do
      it 'returns the default value' do
        expect(subject.ntp_host).to eq('pool.ntp.org')
      end
    end

    describe '#ntp_port' do
      it 'returns the default value' do
        expect(subject.ntp_port).to eq('ntp')
      end
    end

    describe '#ntp_timeout' do
      it 'returns the default value' do
        expect(subject.ntp_timeout).to eq(60)
      end
    end
  end

  context 'with accessor values defined by ENV variables' do
    before do
      stub_env('NTP_HOST', ntp_host_env)
      stub_env('NTP_PORT', ntp_port_env)
      stub_env('NTP_TIMEOUT', ntp_timeout_env)
    end

    describe '#ntp_host' do
      it 'returns defined value from NTP_HOST env variable' do
        expect(subject.ntp_host).to eq(ntp_host_env)
      end
    end

    describe '#ntp_port' do
      it 'returns defined value from NTP_PORT env variable' do
        expect(subject.ntp_port).to eq(ntp_port_env)
      end
    end

    describe '#ntp_timeout' do
      it 'returns defined value from NTP_TIMEOUT env variable' do
        expect(subject.ntp_timeout).to eq(ntp_timeout_env.to_i)
      end
    end
  end

  describe '#multi_check' do
    context 'with custom valid host port and timeout' do
      before do
        stub_env('NTP_HOST', ntp_host_env)
        stub_env('NTP_PORT', ntp_port_env)
        stub_env('NTP_TIMEOUT', ntp_timeout_env)
      end

      it 'passes with a success message' do
        expect_pass

        expect(subject.multi_check).to be_truthy
      end
    end

    context 'with default NTP connection params' do
      it 'passes with a success message' do
        expect_pass

        expect(subject.multi_check).to be_truthy
      end
    end

    context 'when NTP connection times out' do
      it 'fails with a warning message' do
        allow(subject).to receive(:ntp_request).and_raise(Timeout::Error)

        expect_warning('Connection to the NTP Server pool.ntp.org took more than 60 seconds (Timeout)')

        subject.multi_check
      end
    end

    context 'when NTP connection fails' do
      it 'fails with a warning message' do
        allow(subject).to receive(:ntp_request).and_raise(Errno::ECONNREFUSED)

        expect_warning('NTP Server pool.ntp.org cannot be reached')
        subject.multi_check
      end
    end

    context 'when clock difference is greater than max_clock_difference' do
      it 'fails with a message' do
        allow(subject).to receive(:max_clock_difference).and_return(-1)

        expect_failure('Clocks are not in sync with pool.ntp.org NTP server')

        expect(subject.multi_check).to be_falsey
      end
    end
  end

  def expect_failure(reason)
    expect(subject).to receive(:print_failure).with(reason).and_call_original
  end

  def expect_warning(reason)
    expect(subject).to receive(:print_warning).with(reason).and_call_original
  end

  def expect_pass
    expect(subject).to receive(:print_pass).and_call_original
  end
end
