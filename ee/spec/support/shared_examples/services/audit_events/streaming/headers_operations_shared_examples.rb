# frozen_string_literal: true

RSpec.shared_examples 'header creation validation errors' do
  let(:expected_errors) { ["Key can't be blank", "Value can't be blank"] }

  it 'has an array of errors in the response' do
    expect(response).to be_error
    expect(response.errors).to match_array expected_errors
  end
end

RSpec.shared_examples 'does not create audit event' do
  it do
    expect { response }.to not_change { AuditEvent.count }
  end
end

RSpec.shared_examples 'header creation successful' do
  it 'has the header in the response payload' do
    expect(response).to be_success
    expect(response.payload[:header].key).to eq 'a_key'
    expect(response.payload[:header].value).to eq 'a_value'
  end

  it 'creates header for destination' do
    expect { response }
      .to change { destination.headers.count }.by(1)

    destination.headers.reload
    header = destination.headers.last

    expect(header.key).to eq('a_key')
    expect(header.value).to eq('a_value')
  end

  context "with license feature external_audit_events" do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    it 'sends correct event type in audit event stream' do
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(event_type, nil, anything)

      response
    end
  end
end

RSpec.shared_examples 'header updation' do
  context 'when header updation is successful' do
    it 'has the header in the response payload' do
      expect(response).to be_success
      expect(response.payload[:header].key).to eq 'new'
      expect(response.payload[:header].value).to eq 'new'
    end

    it 'updates the header' do
      expect(response).to be_success
      expect(header.reload.key).to eq 'new'
      expect(header.value).to eq 'new'
    end

    context 'with audit events' do
      it 'sends the audit streaming event' do
        audit_context = {
          name: event_type,
          author: user,
          scope: audit_scope,
          target: header,
          message: "Updated a custom HTTP header from key old to have a key new."
        }

        audit_context = audit_context.merge(extra_audit_context)

        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).and_call_original
        expect { response }.to change { AuditEvent.count }.from(0).to(1)
      end

      context "with license feature external_audit_events" do
        before do
          stub_licensed_features(external_audit_events: true)
        end

        context 'when both key and value are updated' do
          it 'creates audit event' do
            expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(event_type, nil, anything)

            response
          end
        end
      end

      context 'when only the header value is updated' do
        let(:params) { super().merge(key: 'old') }

        it 'has a audit message reflecting just the value was changed' do
          audit_context = {
            name: event_type,
            author: user,
            scope: audit_scope,
            target: header,
            message: "Updated a custom HTTP header with key old to have a new value."
          }

          audit_context = audit_context.merge(extra_audit_context)

          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)
          response
        end
      end

      context 'when neither key nor value is updated' do
        let(:params) { super().merge(key: 'old', value: 'old') }

        it_behaves_like 'does not create audit event'
      end
    end
  end

  context 'when header updation is unsuccessful' do
    let(:params) do
      {
        header: header,
        key: '',
        value: 'new'
      }
    end

    it 'does not update the header' do
      expect { subject }.not_to change { header.reload.key }
      expect(header.value).to eq 'old'
    end

    it 'has an error response' do
      expect(response).to be_error
      expect(response.errors)
        .to match_array ["Key can't be blank"]
    end

    it_behaves_like 'does not create audit event'
  end
end

RSpec.shared_examples 'header deletion' do
  context 'when deletion is successful' do
    it 'destroys the header' do
      expect { response }.to change { destination.headers.count }.by(-1)
      expect(response).to be_success
    end

    context 'with audit events' do
      it 'sends the audit streaming event' do
        audit_context = {
          name: event_type,
          author: user,
          scope: audit_scope,
          target: header,
          message: "Destroyed a custom HTTP header with key #{header.key}."
        }

        audit_context = audit_context.merge(extra_audit_context)

        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).and_call_original
        expect { response }.to change { AuditEvent.count }.from(0).to(1)
      end

      context "with license feature external_audit_events" do
        before do
          stub_licensed_features(external_audit_events: true)
        end

        it 'sends correct event type in audit event stream' do
          expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(event_type, nil, anything)

          response
        end
      end
    end
  end

  context 'when deletion is unsuccessful' do
    before do
      allow(header).to receive(:destroy).and_return(false)
      allow(header).to receive(:errors).and_return('foo')
    end

    it 'does not destroy the header' do
      expect { service.execute }.not_to change { destination.headers.count }
    end

    it 'has an error response' do
      response = service.execute

      expect(response).to be_error
      expect(response.errors)
        .to match_array ['foo']
    end

    it_behaves_like 'does not create audit event'
  end
end
