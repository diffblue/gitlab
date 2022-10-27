# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::InitializeAnalyticsWorker do
  let(:jid) { '12345678' }
  let_it_be(:project) { create(:project) }

  subject(:worker) { described_class.new }

  before do
    stub_licensed_features(product_analytics: true)
    allow(worker).to receive(:jid).and_return(jid)
  end

  shared_examples 'a worker that did not make any HTTP calls' do
    it 'makes no HTTP calls to the Jitsu configurator API' do
      subject

      expect(Gitlab::HTTP).not_to receive(:post)
    end
  end

  describe 'perform' do
    subject { worker.perform(project.id) }

    context 'when jitsu_host application setting is not defined' do
      before do
        stub_application_setting(jitsu_host: nil)
      end

      it_behaves_like 'a worker that did not make any HTTP calls'
    end

    context 'when jitsu_project_xid application setting is not defined' do
      before do
        stub_application_setting(jitsu_project_xid: nil)
      end

      it_behaves_like 'a worker that did not make any HTTP calls'
    end

    context 'when all application settings are defined' do
      before do
        stub_application_setting(
          jitsu_host: 'http://jitsu.dev',
          jitsu_project_xid: 'testtesttesttestprj',
          jitsu_administrator_email: 'test@test.com',
          jitsu_administrator_password: 'testtest'
        )
      end

      it 'sends a HTTP request to create a clickhouse destination' do
        expect_next_instance_of(ProductAnalytics::JitsuAuthentication) do |auth|
          expect(auth).to receive(:create_clickhouse_destination!).once
        end

        subject
      end

      context 'when project does not have analytics enabled?' do
        before do
          stub_licensed_features(product_analytics: false)
        end

        it_behaves_like 'a worker that did not make any HTTP calls'
      end

      context 'when project does not exist' do
        subject { worker.perform(non_existing_record_id) }

        it_behaves_like 'a worker that did not make any HTTP calls'
      end
    end
  end
end
