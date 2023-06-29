import AiGenieChatConversation from 'ee/ai/components/ai_genie_chat_conversation.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';

describe('AiGenieChat', () => {
  let wrapper;

  const promptStr = 'foo';
  const messages = [
    {
      role: GENIE_CHAT_MODEL_ROLES.user,
      content: promptStr,
    },
  ];

  const findChatMessages = () => wrapper.findAll('.ai-genie-chat-message');
  const findDelimiter = () => wrapper.findByTestId('conversation-delimiter');
  const createComponent = ({ propsData = {}, data = {}, scopedSlots = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(AiGenieChatConversation, {
      propsData,
      data() {
        return {
          ...data,
        };
      },
      scopedSlots,
      slots,
    });
  };

  describe('rendering', () => {
    it('renders messages when messages are passed', () => {
      createComponent({ propsData: { messages } });
      expect(findChatMessages().at(0).text()).toBe(messages[0].content);
    });

    it('renders delimiter when showDelimiter = true', () => {
      createComponent({ propsData: { messages, showDelimiter: true } });
      expect(findDelimiter().exists()).toBe(true);
    });

    it('does not render delimiter when showDelimiter = false', () => {
      createComponent({ propsData: { messages, showDelimiter: false } });
      expect(findDelimiter().exists()).toBe(false);
    });

    it('converts content of the message from Markdown into HTML', () => {
      createComponent({
        propsData: {
          messages: [
            {
              role: GENIE_CHAT_MODEL_ROLES.user,
              content: '**foo**',
            },
          ],
        },
      });
      expect(findChatMessages().at(0).element.innerHTML).toContain('<strong>foo</strong>');
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
                {
                  role: GENIE_CHAT_MODEL_ROLES.user,
                  content: 'User foo',
                },
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
            messages: [
              {
                role: GENIE_CHAT_MODEL_ROLES.assistant,
                content: slotContent,
              },
            ],
          },
          scopedSlots: {
            feedback: `<template #feedback="slotProps">
              Hello {{ slotProps.message.content }}
              </template>
            `,
          },
        });
        expect(wrapper.text()).toContain(`Hello ${slotContent}`);
      });
    });
  });
});
