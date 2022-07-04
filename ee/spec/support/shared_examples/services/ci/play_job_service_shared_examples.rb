# frozen_string_literal: true

RSpec.shared_examples 'prevents playing job when credit card is required' do
  before do
    allow(::Gitlab).to receive(:com?).and_return(true)
  end

  context 'when user has required credit card' do
    before do
      allow(user)
        .to receive(:has_required_credit_card_to_run_pipelines?)
        .with(project)
        .and_return(true)
    end

    it 'does not raise any exception' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when user does not have required credit card' do
    before do
      allow(::Gitlab::AppLogger).to receive(:info)
      allow(user)
        .to receive(:has_required_credit_card_to_run_pipelines?)
        .with(project)
        .and_return(false)
    end

    it 'raises an exception and logs the failure' do
      expect(::Gitlab::AppLogger)
        .to receive(:info)
        .with(
          message: 'Credit card required to be on file in order to play a job',
          project_path: project.full_path,
          user_id: user.id,
          plan: 'free')

      expect { subject }
        .to raise_error(::Gitlab::Access::AccessDeniedError, 'Credit card required to be on file in order to play a job')
    end
  end
end
