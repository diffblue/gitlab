# frozen_string_literal: true

require "spec_helper"

RSpec.describe EE::Ci::RunnersHelper, feature_category: :continuous_integration do
  let_it_be(:user, refind: true) { create(:user) }
  let_it_be(:namespace) { create(:namespace, owner: user) }
  let_it_be(:project) { create(:project, namespace: namespace) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  shared_examples_for 'minutes notification' do
    let(:show_warning) { true }
    let(:context_level) { project }
    let(:threshold) { double('Ci::Minutes::Notification', show?: show_warning) }

    before do
      allow(::Ci::Minutes::Notification).to receive(:new).and_return(threshold)
    end

    context 'with a project and namespace' do
      context 'when not on dot com' do
        let(:com) { false }

        it { is_expected.to be_falsey }
      end

      context 'when on dot com' do
        it { is_expected.to be_truthy }

        context 'without a persisted project passed' do
          let(:project) { build(:project) }
          let(:context_level) { namespace }

          it { is_expected.to be_truthy }
        end

        context 'without a persisted namespace passed' do
          let(:namespace) { build(:namespace) }

          it { is_expected.to be_truthy }
        end

        context 'with neither a project nor a namespace' do
          let(:project) { build(:project) }
          let(:namespace) { build(:namespace) }

          it { is_expected.to be_falsey }

          context 'when show_pipeline_minutes_notification_dot? has been called before' do
            it 'does not do all the notification and query work again' do
              expect(threshold).not_to receive(:show?)
              expect(project).to receive(:persisted?).once

              helper.show_pipeline_minutes_notification_dot?(project, namespace)

              expect(subject).to be_falsey
            end
          end
        end

        context 'when show notification is falsey' do
          let(:show_warning) { false }

          it { is_expected.to be_falsey }
        end

        context 'when show_pipeline_minutes_notification_dot? has been called before' do
          it 'does not do all the notification and query work again' do
            expect(threshold).to receive(:show?).once
            expect(project).to receive(:persisted?).once

            helper.show_pipeline_minutes_notification_dot?(project, namespace)

            expect(subject).to be_truthy
          end
        end
      end
    end
  end

  describe '#toggle_shared_runners_settings_data' do
    let(:valid_card) { true }

    subject { helper.toggle_shared_runners_settings_data(project) }

    before do
      expect(user).to receive(:has_required_credit_card_to_enable_shared_runners?).with(project).and_return(valid_card)
    end

    context 'when user has a valid credit card' do
      it 'return is_credit_card_validation_required as "false"' do
        expect(subject[:is_credit_card_validation_required]).to eq('false')
      end
    end

    context 'when user does not have a valid credit card' do
      let(:valid_card) { false }

      it 'return is_credit_card_validation_required as "true"' do
        expect(subject[:is_credit_card_validation_required]).to eq('true')
      end
    end
  end

  context 'with notifications' do
    let(:com) { true }

    describe '.show_buy_pipeline_minutes?' do
      subject { helper.show_buy_pipeline_minutes?(project, namespace) }

      context 'when on dot com' do
        it_behaves_like 'minutes notification' do
          before do
            allow(::Gitlab).to receive(:com?).and_return(com)
          end
        end
      end
    end

    describe '.show_pipeline_minutes_notification_dot?' do
      subject { helper.show_pipeline_minutes_notification_dot?(project, namespace) }

      before do
        allow(::Gitlab).to receive(:com?).and_return(com)
      end

      it_behaves_like 'minutes notification'

      context 'when the notification dot has been acknowledged' do
        before do
          create(:callout, user: user, feature_name: described_class::BUY_PIPELINE_MINUTES_NOTIFICATION_DOT)
          expect(helper).not_to receive(:show_out_of_pipeline_minutes_notification?)
        end

        it { is_expected.to be_falsy }
      end

      context 'when the notification dot has not been acknowledged' do
        before do
          expect(helper).to receive(:show_out_of_pipeline_minutes_notification?).and_return(true)
        end

        it { is_expected.to be_truthy }
      end
    end

    describe '.show_buy_pipeline_with_subtext?' do
      subject { helper.show_buy_pipeline_with_subtext?(project, namespace) }

      before do
        allow(::Gitlab).to receive(:com?).and_return(com)
      end

      context 'when the notification dot has not been acknowledged' do
        before do
          expect(helper).not_to receive(:show_out_of_pipeline_minutes_notification?)
        end

        it { is_expected.to be_falsey }
      end

      context 'when the notification dot has been acknowledged' do
        before do
          create(:callout, user: user, feature_name: described_class::BUY_PIPELINE_MINUTES_NOTIFICATION_DOT)
          expect(helper).to receive(:show_out_of_pipeline_minutes_notification?).and_return(true)
        end

        it { is_expected.to be_truthy }
      end
    end

    describe '.root_ancestor_namespace' do
      subject(:root_ancestor) { helper.root_ancestor_namespace(project, namespace) }

      context 'with a project' do
        it 'returns the project root ancestor' do
          expect(root_ancestor).to eq project.root_ancestor
        end
      end

      context 'with only a namespace' do
        let(:project) { nil }

        it 'returns the namespace root ancestor' do
          expect(root_ancestor).to eq namespace.root_ancestor
        end
      end
    end
  end
end
