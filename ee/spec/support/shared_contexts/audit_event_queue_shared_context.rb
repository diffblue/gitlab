# frozen_string_literal: true

RSpec.shared_context 'audit event queue' do
  context 'when audit event queue is active' do
    before do
      allow(::Gitlab::Audit::EventQueue).to receive(:active?).and_return(true)
    end

    it 'adds message to audit event queue' do
      action!

      expect(::Gitlab::Audit::EventQueue.current).to contain_exactly(message)
    end
  end

  context 'when audit event queue is not active' do
    before do
      allow(::Gitlab::Audit::EventQueue).to receive(:active?).and_return(false)
    end

    it 'does not add message to audit event queue' do
      action!

      expect(::Gitlab::Audit::EventQueue.current).to be_empty
    end
  end
end

RSpec.shared_context 'invalid record creates no audit event' do
  before do
    allow(::Gitlab::Audit::EventQueue).to receive(:active?).and_return(true)
  end

  context 'when record is invalid' do
    it 'does not add message to audit event queue' do
      invalid_action

      expect(::Gitlab::Audit::EventQueue.current).to be_empty
    end
  end
end
