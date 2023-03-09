import { GlButton } from '@gitlab/ui';
import Actions from 'ee/status_checks/components/actions.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

const statusCheck = {
  externalUrl: 'https://foo.com',
  id: 1,
  name: 'Foo',
  protectedBranches: [],
};

describe('Status checks actions', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMountExtended(Actions, {
      propsData: {
        statusCheck,
      },
      stubs: {
        GlButton,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  const findEditBtn = () => wrapper.findByTestId('edit-btn');
  const findRemoveBtn = () => wrapper.findByTestId('remove-btn');

  describe.each`
    text           | button           | event
    ${'Edit'}      | ${findEditBtn}   | ${'open-update-modal'}
    ${'Remove...'} | ${findRemoveBtn} | ${'open-delete-modal'}
  `('$text button', ({ text, button, event }) => {
    it(`renders the button text as '${text}'`, () => {
      expect(button().text()).toBe(text);
    });

    it(`sends the status check with the '${event}' event`, () => {
      button().trigger('click');

      expect(wrapper.emitted(event)[0][0]).toStrictEqual(statusCheck);
    });
  });
});
