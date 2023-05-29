# frozen_string_literal: true

RSpec.shared_examples 'streams audit events to external destination' do
  it 'makes one HTTP call' do
    expect(Gitlab::HTTP).to receive(:post).once

    subject
  end

  it 'sends the correct verification header' do
    expect(Gitlab::HTTP).to receive(:post).with(
      an_instance_of(String),
      a_hash_including(
        headers: { "X-Gitlab-Audit-Event-Type" => event_type, 'X-Gitlab-Event-Streaming-Token' => anything })
    ).once

    subject
  end

  it 'adds event type only when audit operation is present' do
    expect(Gitlab::HTTP).to receive(:post).with(
      an_instance_of(String), hash_including(body: a_string_including("\"event_type\":\"#{event_type}\""))
    )

    subject
  end

  context 'and id is always passed in request body' do
    before do
      allow(SecureRandom).to receive(:uuid).and_return('randomtoken')
    end

    it 'sends correct id in request body' do
      if event.id.present?
        expect(Gitlab::HTTP).to receive(:post).with(
          an_instance_of(String), hash_including(body: a_string_including("id\":#{event.id}")))
      else
        expect(Gitlab::HTTP).to receive(:post).with(
          an_instance_of(String), hash_including(body: a_string_including("id\":\"randomtoken\"")))
      end

      subject
    end
  end

  context 'when audit event type is tracked for count' do
    before do
      allow(Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter::KNOWN_EVENTS).to receive(:include?)
                                                                                          .and_return(true)
    end

    it 'tracks the event count and makes http call' do
      expect(Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter).to receive(:count).with(event_type)
      expect(Gitlab::HTTP).to receive(:post).once

      subject
    end
  end

  context 'when audit event type is not tracked for count' do
    before do
      allow(Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter::KNOWN_EVENTS).to receive(:include?)
                                                                                          .and_return(false)
    end

    it 'does not track the event count and makes http call' do
      expect(Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter).not_to receive(:count).with(event_type)
      expect(Gitlab::HTTP).to receive(:post).once

      subject
    end
  end
end

RSpec.shared_examples 'streams audit events to several external destinations' do
  before do
    stub_licensed_features(external_audit_events: true)
  end

  it 'makes the correct number of HTTP calls' do
    expect(Gitlab::HTTP).to receive(:post).with(destination1.destination_url, anything).once
    expect(Gitlab::HTTP).to receive(:post).with(destination2.destination_url, anything).once

    subject
  end
end

RSpec.shared_examples 'does not stream anywhere' do
  it 'makes no HTTP calls' do
    expect(Gitlab::HTTP).not_to receive(:post)

    subject
  end
end

RSpec.shared_examples 'redis connection failure for audit event counter' do
  before do
    allow(Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter).to receive(:count)
                                                                          .and_raise(Redis::CannotConnectError)
  end

  it_behaves_like 'streams audit events to external destination'
end

RSpec.shared_examples 'audit event external destination http post error' do
  context 'when any of Gitlab::HTTP::HTTP_ERRORS is raised' do
    Gitlab::HTTP::HTTP_ERRORS.each do |error_klass|
      context "with #{error_klass}" do
        let(:error) { error_klass.new('error') }

        before do
          allow(Gitlab::HTTP).to receive(:post).and_raise(error)
        end

        it 'does not logs the error' do
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception).with(
            an_instance_of(error_klass)
          )
          subject
        end
      end
    end
  end

  context 'when URI::InvalidURIError exception is raised' do
    let(:error) { URI::InvalidURIError.new('invalid uri') }

    it 'logs the error' do
      allow(Gitlab::HTTP).to receive(:post).and_raise(error)

      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
        an_instance_of(URI::InvalidURIError)
      ).once
      subject
    end
  end
end
