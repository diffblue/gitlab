# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHookService, feature_category: :webhooks do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:project_hook) { create(:project_hook, project: project) }

  let(:service_instance) { described_class.new(project_hook, {}, :push_hooks) }

  describe '#async_execute' do
    context 'when hook has custom context attributes' do
      it 'includes the subscription plan in the worker context' do
        expect(WebHookWorker).to receive(:perform_async) do
          expect(Gitlab::ApplicationContext.current).to include(
            'meta.subscription_plan' => 'default'
          )
        end

        service_instance.async_execute
      end
    end
  end
end
