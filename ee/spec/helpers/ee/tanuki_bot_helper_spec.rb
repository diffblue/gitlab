# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::TanukiBotHelper, feature_category: :global_search do
  let_it_be(:user) { build_stubbed(:user) }

  describe '#show_tanuki_bot_chat?' do
    describe 'when :openai_experimentation and tanuki_bot FF are true' do
      where(:feature_available, :dot_com, :has_paid_namespace, :result) do
        [
          [false, false, false, false],
          [false, true, false, false],
          [false, true, true, false],
          [true, false, false, true],
          [true, true, false, false],
          [true, true, true, true]
        ]
      end

      with_them do
        before do
          allow(helper).to receive(:current_user).and_return(user)
          allow(License).to receive(:feature_available?).and_return(feature_available)
          allow(::Gitlab).to receive(:com?).and_return(dot_com)
          allow(user).to receive(:has_paid_namespace?).and_return(has_paid_namespace)
        end

        it 'returns correct result' do
          expect(helper.show_tanuki_bot_chat?).to be(result)
        end
      end
    end

    describe 'when :openai_experimentation and tanuki_bot FF are not both true' do
      where(:openai_experimentation, :tanuki_bot) do
        [
          [false, false],
          [true, false],
          [false, true]
        ]
      end

      with_them do
        before do
          allow(helper).to receive(:current_user).and_return(user)
          allow(License).to receive(:feature_available?).and_return(true)
          allow(Gitlab).to receive(:com?).and_return(true)
          allow(user).to receive(:has_paid_namespace?).and_return(true)

          stub_feature_flags(openai_experimentation: openai_experimentation)
          stub_feature_flags(tanuki_bot: tanuki_bot)
        end

        it 'returns false' do
          expect(helper.show_tanuki_bot_chat?).to be(false)
        end
      end
    end
  end
end
