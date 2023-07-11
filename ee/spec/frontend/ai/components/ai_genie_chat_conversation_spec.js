import AiGenieChatConversation from 'ee/ai/components/ai_genie_chat_conversation.vue';
import AiGenieChatMessage from 'ee/ai/components/ai_genie_chat_message.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getMarkdown } from '~/rest_api';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE } from '../tanuki_bot/mock_data';

jest.mock('~/rest_api');

describe('AiGenieChat', () => {
  let wrapper;

  const messages = [MOCK_USER_MESSAGE];

  const findChatMessages = () => wrapper.findAllComponents(AiGenieChatMessage);
  const findDelimiter = () => wrapper.findByTestId('conversation-delimiter');
  const createComponent = async ({
    propsData = {},
    data = {},
    scopedSlots = {},
    slots = {},
  } = {}) => {
    wrapper = shallowMountExtended(AiGenieChatConversation, {
      propsData,
      data() {
        return {
          ...data,
        };
      },
      scopedSlots,
      slots,
      stubs: {
        AiGenieChatMessage,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    getMarkdown.mockImplementation(({ text }) => Promise.resolve({ data: { html: text } }));
  });

  describe('rendering', () => {
    const errorStr = 'Error bar';

    it('renders messages when messages are passed', async () => {
      await createComponent({ propsData: { messages } });
      expect(findChatMessages().at(0).text()).toBe(MOCK_USER_MESSAGE.content);
    });

    it('renders delimiter when showDelimiter = true', async () => {
      await createComponent({ propsData: { messages, showDelimiter: true } });
      expect(findDelimiter().exists()).toBe(true);
    });

    it('does not render delimiter when showDelimiter = false', async () => {
      await createComponent({ propsData: { messages, showDelimiter: false } });
      expect(findDelimiter().exists()).toBe(false);
    });

    it.each`
      desc                                                   | msgs                                                           | expected
      ${'content when errors is not available'}              | ${[MOCK_USER_MESSAGE]}                                         | ${MOCK_USER_MESSAGE.content}
      ${'error when contnet is not available'}               | ${[{ ...MOCK_USER_MESSAGE, content: '', errors: [errorStr] }]} | ${errorStr}
      ${'content when both content and error are available'} | ${[{ ...MOCK_USER_MESSAGE, errors: [errorStr] }]}              | ${MOCK_USER_MESSAGE.content}
    `('requests markdown for $desc', async ({ msgs, expected }) => {
      await createComponent({ propsData: { messages: msgs } });
      expect(findChatMessages().at(0).text()).toBe(expected);
    });
  });

  describe('slots', () => {
    const slotContent = 'As Gregor Samsa awoke one morning from uneasy dreams';

    describe('the feedback slot', () => {
      const slotElement = `<template>${slotContent}</template>`;

      it.each(['assistant', 'ASSISTANT'])(
        'renders the content passed to the "feedback" slot when role is %s',
        (role) => {
          createComponent({
            propsData: {
              messages: [
                MOCK_USER_MESSAGE,
                {
                  role,
                  content: 'Assistent bar',
                },
              ],
            },
            scopedSlots: { feedback: slotElement },
          });
          expect(findChatMessages().at(0).text()).not.toContain(slotContent);
          expect(findChatMessages().at(1).text()).toContain(slotContent);
        },
      );

      it('sends correct `message` in the `slotProps` for the components users to consume', () => {
        createComponent({
          propsData: {
            messages: [MOCK_TANUKI_MESSAGE],
          },
          scopedSlots: {
            feedback: `<template #feedback="slotProps">
              Hello {{ slotProps.message.content }} Bye
              </template>
            `,
          },
        });
        expect(wrapper.text()).toContain(`Hello ${MOCK_TANUKI_MESSAGE.content} Bye`);
      });
    });
  });
});
