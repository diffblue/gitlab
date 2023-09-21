import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import AiGenieChatMessage from 'ee/ai/components/ai_genie_chat_message.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import DocumentationSources from 'ee/ai/components/ai_genie_chat_message_sources.vue';
import { TANUKI_BOT_TRACKING_EVENT_NAME } from 'ee/ai/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import {
  MOCK_USER_MESSAGE,
  MOCK_TANUKI_MESSAGE,
  MOCK_CHUNK_MESSAGE,
} from '../tanuki_bot/mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

describe('AiGenieChatMessage', () => {
  let wrapper;

  const findContent = () => wrapper.findComponent({ ref: 'content' });
  const findDocumentSources = () => wrapper.findComponent(DocumentationSources);
  const findUserFeedback = () => wrapper.findComponent(UserFeedback);

  const createComponent = ({
    propsData = { message: MOCK_USER_MESSAGE },
    options = {},
    provides = {},
  } = {}) => {
    wrapper = shallowMountExtended(AiGenieChatMessage, {
      ...options,
      propsData,
      provide: {
        trackingEventName: TANUKI_BOT_TRACKING_EVENT_NAME,
        ...provides,
      },
    });
  };

  it('fails if message is not passed', () => {
    expect(createComponent.bind(null, { propsData: {} })).toThrow();
  });

  describe('rendering', () => {
    it('converts the markdown to html while waiting for the API response', () => {
      createComponent();
      // we do not wait for promises in this test to make sure the content
      // is rendered even before the API response is received
      expect(wrapper.html()).toContain(MOCK_USER_MESSAGE.content);
    });

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders message content', () => {
      expect(wrapper.text()).toBe(MOCK_USER_MESSAGE.content);
    });

    describe('user message', () => {
      it('does not render the documentation sources component', () => {
        expect(findDocumentSources().exists()).toBe(false);
      });

      it('does not render the user feedback component', () => {
        expect(findUserFeedback().exists()).toBe(false);
      });
    });

    describe('assistant message', () => {
      beforeEach(async () => {
        createComponent({
          propsData: { message: MOCK_TANUKI_MESSAGE },
        });
        await waitForPromises();
      });

      it('renders the documentation sources component by default', () => {
        expect(findDocumentSources().exists()).toBe(true);
      });

      it.each([null, undefined, ''])(
        'does not render sources component when `sources` is %s',
        (sources) => {
          createComponent({
            propsData: {
              message: {
                ...MOCK_TANUKI_MESSAGE,
                extras: {
                  sources,
                },
              },
            },
          });
          expect(findDocumentSources().exists()).toBe(false);
        },
      );

      it('renders the user feedback component', () => {
        expect(findUserFeedback().exists()).toBe(true);
      });
    });

    describe('User Feedback component integration', () => {
      it('correctly sets the default tracking event', async () => {
        createComponent({
          propsData: {
            message: MOCK_TANUKI_MESSAGE,
          },
        });
        await waitForPromises();
        expect(findUserFeedback().props('eventName')).toBe(TANUKI_BOT_TRACKING_EVENT_NAME);
      });

      it('correctly sets the tracking event', async () => {
        createComponent({
          propsData: {
            message: MOCK_TANUKI_MESSAGE,
          },
          provides: {
            trackingEventName: 'foo',
          },
        });
        await waitForPromises();
        expect(findUserFeedback().props('eventName')).toBe('foo');
      });
    });
  });

  describe('message output', () => {
    it('clears `messageChunks` buffer', () => {
      createComponent({ options: { messageChunks: ['foo', 'bar'] } });

      expect(wrapper.vm.$options.messageChunks).toEqual([]);
    });

    describe('when `message` contains a chunk', () => {
      it('adds the message chunk to the `messageChunks` buffer', () => {
        createComponent({
          propsData: { message: MOCK_CHUNK_MESSAGE },
          options: { messageChunks: ['foo', 'bar'] },
        });

        expect(wrapper.vm.$options.messageChunks).toEqual([undefined, 'chunk']);
      });
    });

    it('hydrates the message with GLFM when mounting the component', async () => {
      createComponent();
      await nextTick();
      expect(renderGFM).toHaveBeenCalled();
    });

    it('outputs errors if message has no content', () => {
      const errors = ['foo', 'bar', 'baz'];

      createComponent({
        propsData: {
          message: {
            ...MOCK_USER_MESSAGE,
            contentHtml: '',
            content: '',
            errors,
          },
        },
      });

      errors.forEach((err) => {
        expect(findContent().text()).toContain(err);
      });
    });

    describe('message updates watcher', () => {
      const newContent = 'new foo content';
      beforeEach(() => {
        createComponent();
      });

      it('listens to the message changes', async () => {
        expect(findContent().text()).toContain(MOCK_USER_MESSAGE.content);
        // setProps is justified here because we are testing the component's
        // reactive behavior which consistutes an exception
        // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
        wrapper.setProps({
          message: {
            ...MOCK_USER_MESSAGE,
            contentHtml: `<p>${newContent}</p>`,
          },
        });
        await nextTick();
        expect(findContent().text()).not.toContain(MOCK_USER_MESSAGE.content);
        expect(findContent().text()).toContain(newContent);
      });

      it('prioritises the output of contentHtml over content', async () => {
        // setProps is justified here because we are testing the component's
        // reactive behavior which consistutes an exception
        // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
        wrapper.setProps({
          message: {
            ...MOCK_USER_MESSAGE,
            contentHtml: `<p>${MOCK_USER_MESSAGE.content}</p>`,
            content: newContent,
          },
        });
        await nextTick();
        expect(findContent().text()).not.toContain(newContent);
        expect(findContent().text()).toContain(MOCK_USER_MESSAGE.content);
      });

      it('outputs errors if message has no content', async () => {
        // setProps is justified here because we are testing the component's
        // reactive behavior which consistutes an exception
        // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
        wrapper.setProps({
          message: {
            ...MOCK_USER_MESSAGE,
            contentHtml: '',
            content: '',
            errors: ['error'],
          },
        });
        await nextTick();
        expect(findContent().text()).not.toContain(newContent);
        expect(findContent().text()).not.toContain(MOCK_USER_MESSAGE.content);
        expect(findContent().text()).toContain('error');
      });

      it('merges all the errors for output', async () => {
        const errors = ['foo', 'bar', 'baz'];
        // setProps is justified here because we are testing the component's
        // reactive behavior which consistutes an exception
        // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
        wrapper.setProps({
          message: {
            ...MOCK_USER_MESSAGE,
            contentHtml: '',
            content: '',
            errors,
          },
        });
        await nextTick();
        expect(findContent().text()).toContain(errors[0]);
        expect(findContent().text()).toContain(errors[1]);
        expect(findContent().text()).toContain(errors[2]);
      });

      it('hydrates the output message with GLFM if its not a chunk', async () => {
        // setProps is justified here because we are testing the component's
        // reactive behavior which consistutes an exception
        // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
        wrapper.setProps({
          message: {
            ...MOCK_USER_MESSAGE,
            contentHtml: `<p>${newContent}</p>`,
          },
        });
        await nextTick();
        expect(renderGFM).toHaveBeenCalled();
      });
    });
  });

  describe('updates to the message', () => {
    const content1 = 'chunk #1';
    const content2 = ' chunk #2';
    const content3 = ' chunk #3';
    const chunk1 = {
      ...MOCK_CHUNK_MESSAGE,
      content: content1,
      chunkId: 1,
    };
    const chunk2 = {
      ...MOCK_CHUNK_MESSAGE,
      content: content2,
      chunkId: 2,
    };
    const chunk3 = {
      ...MOCK_CHUNK_MESSAGE,
      content: content3,
      chunkId: 3,
    };

    beforeEach(() => {
      createComponent();
    });

    it('does not fail if the message has no chunkId', async () => {
      // setProps is justified here because we are testing the component's
      // reactive behavior which consistutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({
        message: {
          ...MOCK_CHUNK_MESSAGE,
          content: content1,
        },
      });
      await nextTick();
      expect(findContent().text()).toBe(content1);
    });

    it('renders chunks correctly when the chunks arrive out of order', async () => {
      // setProps is justified here because we are testing the component's
      // reactive behavior which consistutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({
        message: chunk2,
      });
      await nextTick();
      expect(findContent().text()).toBe('');

      wrapper.setProps({
        message: chunk1,
      });
      await nextTick();
      expect(findContent().text()).toBe(content1 + content2);

      wrapper.setProps({
        message: chunk3,
      });
      await nextTick();
      expect(findContent().text()).toBe(content1 + content2 + content3);
    });

    it('renders the chunks as they arrive', async () => {
      const consolidatedContent = content1 + content2;

      // setProps is justified here because we are testing the component's
      // reactive behavior which consistutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({
        message: chunk1,
      });
      await nextTick();
      expect(findContent().text()).toBe(content1);

      wrapper.setProps({
        message: chunk2,
      });
      await nextTick();
      expect(findContent().text()).toBe(consolidatedContent);
    });

    it('treats the initial message content as chunk if message has chunkId', async () => {
      createComponent({
        propsData: {
          message: chunk1,
        },
      });
      expect(findContent().text()).toBe(content1);

      // setProps is justified here because we are testing the component's
      // reactive behavior which consistutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({
        message: chunk2,
      });
      await nextTick();
      expect(findContent().text()).toBe(content1 + content2);
    });

    it('does not hydrate the chunk message with GLFM', async () => {
      createComponent({
        propsData: {
          message: chunk1,
        },
      });
      renderGFM.mockClear();
      expect(renderGFM).not.toHaveBeenCalled();

      // setProps is justified here because we are testing the component's
      // reactive behavior which consistutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({
        message: chunk2,
      });
      await nextTick();
      expect(renderGFM).not.toHaveBeenCalled();

      wrapper.setProps({
        message: {
          ...chunk3,
          chunkId: null,
        },
      });
      await nextTick();
      expect(renderGFM).toHaveBeenCalled();
    });
  });
});
