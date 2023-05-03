import { GlLink, GlIcon } from '@gitlab/ui';
import TanukiBotChatMessage from 'ee/ai/tanuki_bot/components/tanuki_bot_chat_message.vue';
import { SOURCE_TYPES, TANUKI_BOT_FEEDBACK_ISSUE_URL } from 'ee/ai/tanuki_bot/constants';
import { renderMarkdown } from '~/notes/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE, MOCK_SOURCE_TYPES } from '../mock_data';

jest.mock('~/notes/utils', () => ({
  renderMarkdown: jest.fn(),
}));

describe('TanukiBotChatMessage', () => {
  let wrapper;

  const defaultProps = {
    messages: MOCK_USER_MESSAGE,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(TanukiBotChatMessage, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findTanukiBotChatMessage = () => wrapper.findByTestId('tanuki-bot-chat-message');
  const findSendFeedbackLink = () => wrapper.findByText('Give feedback');
  const findTanukiBotChatMessageSources = () =>
    wrapper.findByTestId('tanuki-bot-chat-message-sources');
  const findSourceLink = () => findTanukiBotChatMessageSources().findComponent(GlLink);
  const findSourceIcon = () => findTanukiBotChatMessageSources().findComponent(GlIcon);

  describe('when message is a User message', () => {
    beforeEach(() => {
      createComponent({ message: MOCK_USER_MESSAGE });
    });

    it('uses the correct classList', () => {
      expect(findTanukiBotChatMessage().classes()).toEqual(
        expect.arrayContaining(['gl-ml-auto', 'gl-bg-blue-100', 'gl-text-blue-900']),
      );
    });

    it('do not use renderMarkdown to render the message', () => {
      expect(renderMarkdown).not.toHaveBeenCalledWith(MOCK_USER_MESSAGE.msg);
    });

    it('does not render Share Feedback link', () => {
      expect(findSendFeedbackLink().exists()).toBe(false);
    });

    it('does not render sources', () => {
      expect(findTanukiBotChatMessageSources().exists()).toBe(false);
    });
  });

  describe('when message is a Tanuki message', () => {
    describe('default', () => {
      beforeEach(() => {
        createComponent({ message: MOCK_TANUKI_MESSAGE });
      });

      it('uses the correct classList', () => {
        expect(findTanukiBotChatMessage().classes()).toEqual(
          expect.arrayContaining(['tanuki-bot-message', 'gl-text-gray-900']),
        );
      });

      it('uses renderMarkdown to render the message', () => {
        expect(renderMarkdown).toHaveBeenCalledWith(MOCK_TANUKI_MESSAGE.msg);
      });

      it('does render Share Feedback Link', () => {
        expect(findSendFeedbackLink().attributes('href')).toBe(TANUKI_BOT_FEEDBACK_ISSUE_URL);
      });
    });

    describe('Sources', () => {
      describe('when no sources available', () => {
        beforeEach(() => {
          createComponent({ message: { ...MOCK_TANUKI_MESSAGE, sources: [] } });
        });

        it('does not render sources', () => {
          expect(findTanukiBotChatMessageSources().exists()).toBe(false);
        });
      });

      describe('when sources are provided', () => {
        beforeEach(() => {
          createComponent({ message: MOCK_TANUKI_MESSAGE });
        });

        it('does render sources', () => {
          expect(findTanukiBotChatMessageSources().exists()).toBe(true);
        });
      });

      describe.each`
        sourceType               | mockSource                    | expectedText
        ${SOURCE_TYPES.HANDBOOK} | ${MOCK_SOURCE_TYPES.HANDBOOK} | ${MOCK_SOURCE_TYPES.HANDBOOK.title}
        ${SOURCE_TYPES.DOC}      | ${MOCK_SOURCE_TYPES.DOC}      | ${`${MOCK_SOURCE_TYPES.DOC.stage} / ${MOCK_SOURCE_TYPES.DOC.group}`}
        ${SOURCE_TYPES.BLOG}     | ${MOCK_SOURCE_TYPES.BLOG}     | ${`${MOCK_SOURCE_TYPES.BLOG.date} / ${MOCK_SOURCE_TYPES.BLOG.author}`}
      `('when provided source is $sourceType.value', ({ sourceType, mockSource, expectedText }) => {
        beforeEach(() => {
          createComponent({ message: { ...MOCK_TANUKI_MESSAGE, sources: [mockSource] } });
        });

        it('renders the correct icon', () => {
          expect(findSourceIcon().props('name')).toBe(sourceType.icon);
        });

        it('renders the correct link URL', () => {
          expect(findSourceLink().attributes('href')).toBe(mockSource.source_url);
        });

        it('renders the correct link text', () => {
          expect(findSourceLink().text()).toBe(expectedText);
        });
      });
    });
  });
});
