# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Elasticsearchable, feature_category: :global_search do
  let(:class_instance) { subject_class.new(current_user, params) }
  let_it_be(:current_user) { create(:user) }
  let(:params) { {} }
  let(:subject_class) do
    Class.new do
      attr_accessor :current_user, :params

      include Search::Elasticsearchable

      def initialize(current_user, params)
        @params = params
        @current_user = current_user
      end

      def elasticsearchable_scope
        nil
      end
    end
  end

  describe "#use_elasticsearch?" do
    it 'is false' do
      expect(class_instance).not_to be_use_elasticsearch
    end

    context 'when search_using_elasticsearch setting is enabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:search_using_elasticsearch?).and_return(true)
      end

      context 'when basic_search param is passed in' do
        let(:params) { { basic_search: true } }

        it 'is false' do
          expect(class_instance).not_to be_use_elasticsearch
        end
      end

      context 'when scope is epics' do
        let(:params) { { scope: 'epics' } }

        it 'is false' do
          expect(class_instance).not_to be_use_elasticsearch
        end
      end

      context 'when scope is notes' do
        let(:params) { { scope: 'notes' } }

        it 'is true' do
          expect(class_instance).to be_use_elasticsearch
        end
      end

      context 'when scope is users' do
        let(:params) { { scope: 'users' } }

        [true, false].each do |matcher|
          it 'is equal to advanced_user_search?' do
            allow(class_instance).to receive(:advanced_user_search?).and_return(matcher)

            expect(class_instance.use_elasticsearch?).to eq(matcher)
          end
        end
      end
    end
  end

  describe "#advanced_user_search?" do
    it 'is true when the scope is not users' do
      expect(class_instance).to be_advanced_user_search
    end

    context 'when scope is users' do
      using RSpec::Parameterized::TableSyntax

      let(:params) { { scope: 'users' } }

      where(:advanced_user_search_enabled, :create_user_index_finished, :backfill_users_finished, :result) do
        true | true | true | true
        true | true | false | false
        true | false | true | false
        true | false | false | false
        false | true | true | false
        false | false | false | false
      end

      with_them do
        it 'returns the correct result' do
          stub_feature_flags(advanced_user_search: advanced_user_search_enabled)

          allow(Elastic::DataMigrationService).to receive(:migration_has_finished?)
          .with(:create_user_index).and_return(create_user_index_finished)

          allow(Elastic::DataMigrationService).to receive(:migration_has_finished?)
          .with(:backfill_users).and_return(backfill_users_finished)

          expect(class_instance.advanced_user_search?).to eq(result)
        end
      end
    end
  end
end
