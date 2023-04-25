import { GlButton, GlSkeletonLoader, GlBadge, GlForm } from '@gitlab/ui';
import { nextTick } from 'vue';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { i18n, GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';

describe('AiGenieChat', () => {
  let wrapper;

  const createComponent = ({ propsData = {}, data = {}, slots = {}, glFeatures = {} } = {}) => {
    wrapper = shallowMountExtended(AiGenieChat, {
      propsData,
      data() {
        return {
          ...data,
        };
      },
      slots,
      provide: {
        glFeatures,
      },
    });
  };

  const findChatComponent = () => wrapper.findByTestId('chat-component');
  const findCloseButton = () => wrapper.findComponent(GlButton);
  const findSceletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findChatMessages = () => wrapper.findAll('.ai-genie-chat-message');
  const findError = () => wrapper.findByTestId('chat-error');
  const findGeneratedByAI = () => wrapper.findByText(i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI);
  const findWarning = () => wrapper.findByTestId('chat-legal-warning');
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findChatInput = () => wrapper.findByTestId('chat-prompt-input');
  const findChatInputForm = () => wrapper.findComponent(GlForm);

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    describe('default', () => {
      it.each`
        desc                                       | component             | shouldRender
        ${'renders root component'}                | ${findChatComponent}  | ${true}
        ${'renders experimental label'}            | ${findBadge}          | ${true}
        ${'renders a generated by AI note'}        | ${findGeneratedByAI}  | ${true}
        ${'renders a legal warning when rendered'} | ${findWarning}        | ${true}
        ${'does not render loading skeleton'}      | ${findSceletonLoader} | ${false}
        ${'does not render chat error'}            | ${findError}          | ${false}
        ${'does not render chat input'}            | ${findChatInput}      | ${false}
      `('$desc', ({ component, shouldRender }) => {
        expect(component().exists()).toBe(shouldRender);
      });
    });

    it('renders the content passed to the "feedback" slot for assistant messages only', () => {
      const messages = [
        {
          role: GENIE_CHAT_MODEL_ROLES.user,
          content: 'foo',
        },
        {
          role: GENIE_CHAT_MODEL_ROLES.assistant,
          content: 'bar',
        },
      ];
      const slotContent = 'I am feedback';
      createComponent({
        propsData: {
          messages,
        },
        slots: { feedback: slotContent },
      });
      expect(findChatMessages().at(0).text()).not.toContain(slotContent);
      expect(findChatMessages().at(1).text()).toContain(slotContent);
    });

    it('renders the content passed to the "hero" slot', () => {
      const slotContent = 'As Gregor Samsa awoke one morning from uneasy dreams';
      createComponent({ slots: { hero: slotContent } });
      expect(findChatComponent().text()).toContain(slotContent);
    });

    it('sets correct props on the Experiment label', () => {
      const badgeType = 'info';
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

    it('renders skeleton when isLoading', () => {
      createComponent({ propsData: { isLoading: true } });
      expect(findSceletonLoader().exists()).toBe(true);
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

    describe('chat', () => {
      describe('with the flag off', () => {
        beforeEach(() => {
          createComponent({ propsData: { messages }, glFeatures: { explainCodeChat: false } });
        });

        it('does not render prompt input even if there are messages to show', () => {
          expect(findChatInput().exists()).toBe(false);
        });
      });
      describe('with the flag on', () => {
        beforeEach(() => {
          createComponent({ propsData: { messages }, glFeatures: { explainCodeChat: true } });
        });

        it('renders prompt input if there are messages to show', () => {
          expect(findChatInput().exists()).toBe(true);
        });

        it('emits event when user submits a message', () => {
          const prompt = 'foo';
          findChatInput().vm.$emit('input', prompt);
          findChatInputForm().vm.$emit('submit', {
            preventDefault: jest.fn(),
            stopPropagation: jest.fn(),
          });
          expect(wrapper.emitted('send-chat-prompt')[0]).toEqual([prompt]);
        });
      });
    });
  });
});
