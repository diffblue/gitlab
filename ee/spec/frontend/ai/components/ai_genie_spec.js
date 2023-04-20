import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import AiGenie from 'ee/ai/components/ai_genie.vue';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import { generatePrompt } from 'ee/ai/utils';
import { i18n } from 'ee/ai/constants';
import { renderMarkdown } from '~/notes/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import explainCodeMutation from 'ee/ai/graphql/explain_code.mutation.graphql';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';

const aiResponseFormatted = 'Formatted AI response';

jest.mock('ee/ai/utils');
jest.mock('~/notes/utils', () => ({
  renderMarkdown: jest.fn().mockReturnValue(aiResponseFormatted),
}));

Vue.use(VueApollo);

const aiResponse = 'AI response';
const explainCodeMutationResponse = { data: { aiAction: { errors: [] } } };
const explainCodeSubscriptionResponse = {
  data: { aiCompletionResponse: { responseBody: aiResponse, errors: [] } },
};

const SELECTION_START_POSITION = 50;
const SELECTION_END_POSITION = 150;
const CONTAINER_TOP = 20;
const SELECTED_TEXT = 'Foo';

let mutationHandlerMock;
let subscriptionHandlerMock;

describe('AiGenie', () => {
  let wrapper;
  const containerId = 'container';
  const language = 'vue';
  const resourceId = 'gid://gitlab/Project/1';
  const userId = 'gid://gitlab/User/1';

  const getContainer = () => document.getElementById(containerId);
  const createComponent = (propsData = {}) => {
    const apolloProvider = createMockApollo([
      [aiResponseSubscription, subscriptionHandlerMock],
      [explainCodeMutation, mutationHandlerMock],
    ]);

    wrapper = shallowMountExtended(AiGenie, {
      propsData,
      provide: { resourceId, userId },
      stubs: {
        AiGenieChat,
      },
      apolloProvider,
    });
  };
  const findButton = () => wrapper.findComponent(GlButton);
  const findGenieChat = () => wrapper.findComponent(AiGenieChat);
  const getRangeAtMock = (top = () => 0) => {
    return jest.fn((rangePosition) => {
      return {
        getBoundingClientRect: jest.fn(() => {
          return {
            top: top(rangePosition),
            left: 0,
            right: 0,
            bottom: 0,
          };
        }),
      };
    });
  };
  const getSelectionMock = ({ getRangeAt = getRangeAtMock(), toString = () => {} } = {}) => {
    return {
      anchorNode: document.getElementById('first-paragraph'),
      isCollapsed: false,
      getRangeAt,
      rangeCount: 10,
      toString,
    };
  };

  const simulateSelectionEvent = () => {
    const selectionChangeEvent = new Event('selectionchange');
    document.dispatchEvent(selectionChangeEvent);
  };

  const waitForDebounce = async () => {
    await nextTick();
    jest.runOnlyPendingTimers();
  };

  const simulateSelectText = async ({
    contains = true,
    getSelection = getSelectionMock(),
  } = {}) => {
    jest.spyOn(window, 'getSelection').mockImplementation(() => getSelection);
    jest.spyOn(document.getElementById(containerId), 'contains').mockImplementation(() => contains);
    simulateSelectionEvent();
    await waitForDebounce();
  };

  const requestExplanation = async () => {
    await findButton().vm.$emit('click');
  };

  beforeEach(() => {
    mutationHandlerMock = jest.fn().mockResolvedValue(explainCodeMutationResponse);
    subscriptionHandlerMock = jest.fn().mockResolvedValue(explainCodeSubscriptionResponse);
    setHTMLFixture(
      `<div id="${containerId}" style="height:1000px; width: 800px"><p lang=${language} id="first-paragraph">Foo</p></div>`,
    );
  });

  afterEach(() => {
    resetHTMLFixture();
    mutationHandlerMock.mockRestore();
    subscriptionHandlerMock.mockRestore();
  });

  it('correctly renders the component by default', () => {
    createComponent({ containerId });
    expect(findButton().exists()).toBe(true);
    expect(findGenieChat().exists()).toBe(false);
  });

  describe('the toggle button', () => {
    beforeEach(() => {
      createComponent({ containerId });
    });

    it('is hidden by default, yet gets the correct props', () => {
      const btnWrapper = findButton();
      expect(btnWrapper.isVisible()).toBe(false);
      expect(btnWrapper.attributes('title')).toBe(i18n.GENIE_TOOLTIP);
    });

    it('is rendered when a text is selected', async () => {
      await simulateSelectText();
      expect(findButton().isVisible()).toBe(true);
    });

    describe('toggle position', () => {
      beforeEach(() => {
        jest.spyOn(getContainer(), 'getBoundingClientRect').mockImplementation(() => {
          return { top: CONTAINER_TOP };
        });
      });

      it('is positioned correctly at the start of the selection', async () => {
        const getRangeAt = getRangeAtMock((position) => {
          return position === 0 ? SELECTION_START_POSITION : SELECTION_END_POSITION;
        });
        const getSelection = getSelectionMock({ getRangeAt });
        await simulateSelectText({ getSelection });
        expect(wrapper.element.style.top).toBe(`${SELECTION_START_POSITION - CONTAINER_TOP}px`);
      });

      it('is positioned correctly at the end of the selection', async () => {
        const getRangeAt = getRangeAtMock((position) => {
          return position === 0 ? SELECTION_END_POSITION : SELECTION_START_POSITION;
        });
        const getSelection = getSelectionMock({ getRangeAt });
        await simulateSelectText({ getSelection });
        expect(wrapper.element.style.top).toBe(`${SELECTION_START_POSITION - CONTAINER_TOP}px`);
      });
    });
  });

  describe('selectionchange event listener', () => {
    let addEventListenerSpy;
    let removeEventListenerSpy;

    beforeEach(() => {
      addEventListenerSpy = jest.spyOn(document, 'addEventListener');
      removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');
      createComponent({ containerId });
    });

    afterEach(() => {
      addEventListenerSpy.mockRestore();
      removeEventListenerSpy.mockRestore();
    });

    it('sets up the `selectionchange` event listener', () => {
      expect(addEventListenerSpy).toHaveBeenCalledWith('selectionchange', expect.any(Function));
      expect(removeEventListenerSpy).not.toHaveBeenCalled();
    });

    it('removes the event listener when destroyed', () => {
      wrapper.destroy();
      expect(removeEventListenerSpy).toHaveBeenCalledWith('selectionchange', expect.any(Function));
    });
  });

  describe('interaction', () => {
    beforeEach(() => {
      createComponent({ containerId });
    });

    it('toggles genie when the button is clicked', async () => {
      findButton().vm.$emit('click');
      await nextTick();
      expect(findGenieChat().exists()).toBe(true);
    });

    it('calls a GraphQL mutation when explain code requested', async () => {
      await requestExplanation();
      expect(generatePrompt).toHaveBeenCalledTimes(1);
      expect(mutationHandlerMock).toHaveBeenCalledWith({ resourceId });
    });

    it('calls the subscription with correct variables', async () => {
      await requestExplanation();
      await waitForPromises();
      expect(subscriptionHandlerMock).toHaveBeenCalledWith({ resourceId, userId });
    });

    it('once the response arrives, :content is set with the response message', async () => {
      await requestExplanation();
      await waitForPromises();
      await nextTick();
      expect(subscriptionHandlerMock).toHaveBeenCalledWith({ resourceId, userId });
      expect(renderMarkdown).toHaveBeenCalledWith(aiResponse);
      expect(findGenieChat().props().content).toBe(aiResponseFormatted);
    });

    it('when a snippet is selected, :selected-text gets the same content', async () => {
      const toString = () => SELECTED_TEXT;
      const getSelection = getSelectionMock({ toString });
      await simulateSelectText({ getSelection });
      await requestExplanation();
      expect(findGenieChat().props().selectedText).toBe(SELECTED_TEXT);
    });

    it('sets the snippet language', async () => {
      await simulateSelectText();
      await requestExplanation();
      expect(findGenieChat().props().snippetLanguage).toBe(language);
    });

    describe('error handling', () => {
      it('if the subscription fails, genie gets :error set with the error message', async () => {
        subscriptionHandlerMock = jest.fn().mockRejectedValue({ errors: [] });
        createComponent({ containerId });
        await requestExplanation();
        await waitForPromises();
        expect(findGenieChat().props().error).toBe(i18n.REQUEST_ERROR);
      });
      it('if the mutation fails, genie gets :error set with the error message', async () => {
        mutationHandlerMock = jest.fn().mockRejectedValue();
        createComponent({ containerId });
        await requestExplanation();
        await waitForPromises();
        expect(findGenieChat().props().error).toBe(i18n.REQUEST_ERROR);
      });
    });
  });
});
