import AiGenieChatConversation from 'ee/ai/components/ai_genie_chat_conversation.vue';
import AiGenieChatMessage from 'ee/ai/components/ai_genie_chat_message.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE } from '../tanuki_bot/mock_data';

describe('AiGenieChatConversation', () => {
  let wrapper;

  const messages = [MOCK_USER_MESSAGE];

  const findChatMessages = () => wrapper.findAllComponents(AiGenieChatMessage);
  const findDelimiter = () => wrapper.findByTestId('conversation-delimiter');
  const createComponent = async ({ propsData = {}, data = {} } = {}) => {
    wrapper = shallowMountExtended(AiGenieChatConversation, {
      propsData,
      data() {
        return {
          ...data,
        };
      },
    });
    await waitForPromises();
  };

  describe('rendering', () => {
    it('renders messages when messages are passed', async () => {
      await createComponent({ propsData: { messages: [MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE] } });
      expect(findChatMessages().length).toBe(2);
    });

    it('renders delimiter when showDelimiter = true', async () => {
      await createComponent({ propsData: { messages, showDelimiter: true } });
      expect(findDelimiter().exists()).toBe(true);
    });

    it('does not render delimiter when showDelimiter = false', async () => {
      await createComponent({ propsData: { messages, showDelimiter: false } });
      expect(findDelimiter().exists()).toBe(false);
    });
  });
});
