import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import AiGenieChatMessage from 'ee/ai/components/ai_genie_chat_message.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';
import { getMarkdown } from '~/rest_api';
import {
  MOCK_USER_MESSAGE,
  MOCK_TANUKI_MESSAGE,
  MOCK_CHUNK_MESSAGE,
} from '../tanuki_bot/mock_data';

jest.mock('~/rest_api');

describe('AiGenieChatMessage', () => {
  let wrapper;

  const findContent = () => wrapper.findComponent({ ref: 'content' });

  const createComponent = ({
    propsData = { message: MOCK_USER_MESSAGE },
    scopedSlots = {},
    options = {},
  } = {}) => {
    wrapper = shallowMountExtended(AiGenieChatMessage, {
      ...options,
      propsData,
      scopedSlots,
    });
  };
  beforeEach(() => {
    getMarkdown.mockImplementation(({ text }) => Promise.resolve({ data: { html: text } }));
  });

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

    const slotContent = 'As Gregor Samsa awoke one morning from uneasy dreams';

    describe('the feedback slot', () => {
      const slotElement = `<template>${slotContent}</template>`;

      it.each`
        role                                | expectedToContainSlotContent
        ${GENIE_CHAT_MODEL_ROLES.user}      | ${false}
        ${GENIE_CHAT_MODEL_ROLES.system}    | ${false}
        ${GENIE_CHAT_MODEL_ROLES.assistant} | ${true}
      `(
        'renders the content passed to the "feedback" slot when role is $role',
        async ({ role, expectedToContainSlotContent }) => {
          createComponent({
            propsData: {
              message: {
                ...MOCK_USER_MESSAGE,
                role,
              },
            },
            scopedSlots: { feedback: slotElement },
          });
          await waitForPromises();
          if (expectedToContainSlotContent) {
            expect(wrapper.text()).toContain(slotContent);
          } else {
            expect(wrapper.text()).toBe(MOCK_USER_MESSAGE.content);
          }
        },
      );

      it('sends correct `message` in the `slotProps` for the components users to consume', () => {
        createComponent({
          propsData: {
            message: {
              ...MOCK_TANUKI_MESSAGE,
              content: slotContent,
            },
            promptLocation: 'foo',
          },
          scopedSlots: {
            feedback: `<template #feedback="slotProps">
              Hello {{ slotProps.message.content }} and {{ slotProps.promptLocation }}
              </template>
            `,
          },
        });
        expect(wrapper.text()).toContain(`Hello ${slotContent} and foo`);
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

    it('hydrates the message with GLFM when mounting the component', () => {
      createComponent();
      expect(getMarkdown).toHaveBeenCalledWith({ text: MOCK_USER_MESSAGE.content, gfm: true });
    });

    it('listens to the message changes', async () => {
      const newContent = 'new foo content';
      createComponent();
      // setProps is justified here because we are testing the component's
      // reactive behavior which consistutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({
        message: {
          ...MOCK_USER_MESSAGE,
          content: newContent,
        },
      });
      await nextTick();
      expect(findContent().text()).not.toContain(MOCK_USER_MESSAGE.content);
      expect(findContent().text()).toContain(newContent);
    });
  });

  describe('updates to the message', () => {
    const content1 = 'chunk #1';
    const content2 = ' chunk #2';
    const content3 = ' chunk #3';
    const chunk1 = {
      ...MOCK_USER_MESSAGE,
      content: content1,
      chunkId: 1,
    };
    const chunk2 = {
      ...MOCK_USER_MESSAGE,
      content: content2,
      chunkId: 2,
    };
    const chunk3 = {
      ...MOCK_USER_MESSAGE,
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
          ...MOCK_USER_MESSAGE,
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

    it('hydrates the message with GLFM when the updated message is not a chunk', async () => {
      createComponent({
        propsData: {
          message: chunk1,
        },
      });
      getMarkdown.mockClear();
      expect(getMarkdown).not.toHaveBeenCalled();

      // setProps is justified here because we are testing the component's
      // reactive behavior which consistutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({
        message: chunk2,
      });
      await nextTick();
      expect(getMarkdown).not.toHaveBeenCalled();

      wrapper.setProps({
        message: {
          ...chunk3,
          chunkId: null,
        },
      });
      await nextTick();
      expect(getMarkdown).toHaveBeenCalledWith({ text: content3, gfm: true });
    });
  });
});
