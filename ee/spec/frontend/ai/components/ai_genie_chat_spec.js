import { GlButton, GlBadge } from '@gitlab/ui';
import { nextTick } from 'vue';
import AiGenieLoader from 'ee/ai/components/ai_genie_loader.vue';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { i18n, GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';

describe('AiGenieChat', () => {
  let wrapper;

  const createComponent = ({ propsData = {}, data = {}, scopedSlots = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(AiGenieChat, {
      propsData,
      data() {
        return {
          ...data,
        };
      },
      scopedSlots,
      slots,
      stubs: {
        AiGenieLoader,
      },
    });
  };

  const findChatComponent = () => wrapper.findByTestId('chat-component');
  const findCloseButton = () => wrapper.findComponent(GlButton);
  const findCustomLoader = () => wrapper.findComponent(AiGenieLoader);
  const findChatMessages = () => wrapper.findAll('.ai-genie-chat-message');
  const findError = () => wrapper.findByTestId('chat-error');
  const findGeneratedByAI = () => wrapper.findByText(i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI);
  const findWarning = () => wrapper.findByTestId('chat-legal-warning');
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findChatInput = () => wrapper.findByTestId('chat-prompt-input');
  const findCloseChatButton = () => wrapper.findByTestId('chat-close-button');

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    describe('default', () => {
      it.each`
        desc                                  | component            | shouldRender
        ${'renders root component'}           | ${findChatComponent} | ${true}
        ${'renders experimental label'}       | ${findBadge}         | ${true}
        ${'does not render loading skeleton'} | ${findCustomLoader}  | ${false}
        ${'does not render chat error'}       | ${findError}         | ${false}
        ${'does not render chat input'}       | ${findChatInput}     | ${false}
      `('$desc', ({ component, shouldRender }) => {
        expect(component().exists()).toBe(shouldRender);
      });
    });

    describe('slots', () => {
      const slotContent = 'As Gregor Samsa awoke one morning from uneasy dreams';

      describe('the feedback slot', () => {
        const slotElement = `<template>${slotContent}</template>`;
        const messages = [
          {
            role: GENIE_CHAT_MODEL_ROLES.user,
            content: 'User foo',
          },
          {
            role: GENIE_CHAT_MODEL_ROLES.assistant,
            content: 'Assistent bar',
          },
        ];

        it('renders the content passed to the "feedback" slot for assistant messages only', () => {
          createComponent({
            propsData: {
              messages,
            },
            scopedSlots: { feedback: slotElement },
          });
          expect(findChatMessages().at(0).text()).not.toContain(slotContent);
          expect(findChatMessages().at(1).text()).toContain(slotContent);
        });
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

      it.each`
        desc                 | slot            | content        | isChatAvailable | shouldRenderSlotContent
        ${'renders'}         | ${'hero'}       | ${slotContent} | ${true}         | ${true}
        ${'renders'}         | ${'hero'}       | ${slotContent} | ${false}        | ${true}
        ${'does not render'} | ${'input-help'} | ${slotContent} | ${false}        | ${false}
        ${'renders'}         | ${'input-help'} | ${slotContent} | ${true}         | ${true}
      `(
        '$desc the $content passed to the $slot slot when isChatAvailable is $isChatAvailable',
        ({ slot, content, isChatAvailable, shouldRenderSlotContent }) => {
          createComponent({
            propsData: { isChatAvailable },
            slots: { [slot]: content },
          });
          if (shouldRenderSlotContent) {
            expect(wrapper.text()).toContain(content);
          } else {
            expect(wrapper.text()).not.toContain(content);
          }
        },
      );

      describe('subheader slot', () => {
        describe('default content', () => {
          it('renders a generated by AI note', () => {
            expect(findGeneratedByAI().exists()).toBe(true);
          });

          it('renders a legal warning', () => {
            expect(findWarning().exists()).toBe(true);
          });
        });

        it('renders the content passed to the "subheader" slot instead of the default content', () => {
          createComponent({ slots: { subheader: slotContent } });
          expect(findChatComponent().text()).toContain(slotContent);
          expect(findGeneratedByAI().exists()).toBe(false);
          expect(findWarning().exists()).toBe(false);
        });
      });
    });

    it('sets correct props on the Experiment label', () => {
      const badgeType = 'muted';
      const badgeSize = 'md';
      expect(findBadge().props('variant')).toBe(badgeType);
      expect(findBadge().props('size')).toBe(badgeSize);
      expect(findBadge().text()).toBe(i18n.EXPERIMENT_BADGE);
    });
  });

  describe('interaction', () => {
    const promptStr = 'foo';
    const messages = [
      {
        role: GENIE_CHAT_MODEL_ROLES.user,
        content: promptStr,
      },
    ];

    it('is hidden after the header button is clicked', async () => {
      findCloseButton().vm.$emit('click');
      await nextTick();
      expect(findChatComponent().exists()).toBe(false);
    });

    it('resets the hidden status of the component on loading', async () => {
      createComponent({ data: { isHidden: true } });
      expect(findChatComponent().exists()).toBe(false);
      // setProps is justified here because we are testing the component's
      // reactive behavior which consistutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({
        isLoading: true,
      });
      await nextTick();
      expect(findChatComponent().exists()).toBe(true);
    });

    it('renders custom loader when isLoading', () => {
      createComponent({ propsData: { isLoading: true } });
      expect(findCustomLoader().exists()).toBe(true);
    });

    it('renders alert if error', () => {
      const errorMessage = 'Something went Wrong';
      createComponent({ propsData: { error: errorMessage } });
      expect(findError().text()).toBe(errorMessage);
    });

    it('renders messages when messages are passed', () => {
      createComponent({ propsData: { messages } });
      expect(findChatMessages().at(0).text()).toBe(promptStr);
    });

    it('hides the chat on button click and emits an event', () => {
      createComponent({ propsData: { messages } });
      expect(wrapper.vm.$data.isHidden).toBe(false);
      findCloseChatButton().vm.$emit('click');
      expect(wrapper.vm.$data.isHidden).toBe(true);
      expect(wrapper.emitted('chat-hidden')).toBeDefined();
    });

    describe('chat', () => {
      it('does not render prompt input by default', () => {
        createComponent({ propsData: { messages } });
        expect(findChatInput().exists()).toBe(false);
      });

      it('renders prompt input if `isChatAvailable` prop is `true`', () => {
        createComponent({ propsData: { messages, isChatAvailable: true } });
        expect(findChatInput().exists()).toBe(true);
      });
    });
  });
});
