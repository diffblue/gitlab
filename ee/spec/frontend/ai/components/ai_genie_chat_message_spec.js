import waitForPromises from 'helpers/wait_for_promises';
import AiGenieChatMessage from 'ee/ai/components/ai_genie_chat_message.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';
import { getMarkdown } from '~/rest_api';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE } from '../tanuki_bot/mock_data';

jest.mock('~/rest_api');

describe('AiGenieChatMessage', () => {
  let wrapper;

  const createComponent = ({
    propsData = { message: MOCK_USER_MESSAGE },
    scopedSlots = {},
  } = {}) => {
    wrapper = shallowMountExtended(AiGenieChatMessage, {
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
});
