# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::LogCursor::Logger, :geo, feature_category: :geo_replication do
  subject(:logger) { described_class.new(LoggerSpec) }

  let(:data) { { pid: 111, class: 'LoggerSpec', gitlab_host: 'localhost', message: 'Test' } }

  before do
    stub_const('LoggerSpec', Class.new)
    stub_const("#{described_class.name}::PID", 111)
  end

  it 'logs an info event' do
    expect(::Gitlab::JsonLogger).to receive(:info).with(data)

    logger.info('Test')
  end

  it 'logs a warning event' do
    expect(::Gitlab::JsonLogger).to receive(:warn).with(data)

    logger.warn('Test')
  end

  it 'logs an error event' do
    expect(::Gitlab::JsonLogger).to receive(:error).with(data)

    logger.error('Test')
  end

  describe '.event_info' do
    it 'logs an info event' do
      expect(::Gitlab::JsonLogger).to receive(:info).with(
        {
          pid: 111,
          class: "LoggerSpec",
          gitlab_host: 'localhost',
          message: 'Test',
          cursor_delay_s: 0.0
        }
      )

      logger.event_info(Time.now, 'Test')
    end
  end

  context 'when class is extended with StdoutLogger' do
    it 'logs to stdout' do
      message = 'this message should appear on stdout'
      Gitlab::Geo::Logger.extend(Gitlab::Geo::Logger::StdoutLogger)
      # This is needed because otherwise https://gitlab.com/gitlab-org/gitlab/blob/master/config/environments/test.rb#L52
      # sets the default logging level to :fatal when running under CI
      allow(Rails.logger).to receive(:level).and_return(:info)

      expect { logger.info(message) }.to output(/#{message}/).to_stdout
    end
  end
end
