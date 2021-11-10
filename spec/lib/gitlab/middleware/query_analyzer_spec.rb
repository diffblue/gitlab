# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::QueryAnalyzer, query_analyzers: false do
  describe 'the PreventCrossDatabaseModification' do
    describe '#call' do
      let(:app) { double(:app) }
      let(:middleware) { described_class.new(app) }
      let(:env) { {} }

      subject { middleware.call(env) }

      context 'when there is a cross modification' do
        before do
          allow(app).to receive(:call) do
            Project.transaction do
              Project.where(id: -1).update_all(id: -1)
              ::Ci::Pipeline.where(id: -1).update_all(id: -1)
            end
          end
        end

        it 'detects cross modifications and logs them without raising exception' do
          allow(Rails.env).to receive(:test?).and_return(false)
          expect(::Gitlab::ErrorTracking).to receive(:track_exception)

          expect { subject }.not_to raise_error
        end

        context 'when the detect_cross_database_modification is disabled' do
          before do
            stub_feature_flags(detect_cross_database_modification: false)
          end

          it 'does not detect cross modifications' do
            expect(::Gitlab::ErrorTracking).not_to receive(:track_exception)

            subject
          end
        end
      end

      context 'when there is no cross modification' do
        before do
          allow(app).to receive(:call) do
            Project.transaction do
              Project.where(id: -1).update_all(id: -1)
              Namespace.where(id: -1).update_all(id: -1)
            end
          end
        end

        it 'does not log anything' do
          expect(::Gitlab::ErrorTracking).not_to receive(:track_exception)

          subject
        end
      end
    end
  end
end
