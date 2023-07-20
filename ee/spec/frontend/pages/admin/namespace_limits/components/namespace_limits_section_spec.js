import { nextTick } from 'vue';
import { GlFormInput, GlModal, GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceLimitsSection from 'ee/pages/admin/namespace_limits/components/namespace_limits_section.vue';
import NamespaceLimitsChangelog from 'ee/pages/admin/namespace_limits/components/namespace_limits_changelog.vue';

describe('NamespaceLimitsSection', () => {
  let wrapper;

  const defaultProps = {
    label: 'Set notifications limit',
    modalBody: 'Do you confirm changing notifications limits for all free namespaces?',
    changelogEntries: [],
    limit: 10,
  };
  const glModalDirective = jest.fn();

  const createComponent = (props = {}) => {
    wrapper = mountExtended(NamespaceLimitsSection, {
      propsData: { ...defaultProps, ...props },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
    });
  };

  const findUpdateLimitButton = () => wrapper.findByText('Update limit');
  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findChangelogComponent = () => wrapper.findComponent(NamespaceLimitsChangelog);

  describe('showing alert', () => {
    it('shows the alert if there is `errorMessage` passed to the component', () => {
      const errorMessage = 'Sample error message for namespace_limits_section';
      createComponent({ errorMessage });

      expect(findAlert().text()).toBe(errorMessage);
    });

    it('does not show the alert if there is no `errorMessage` passed to the component', () => {
      createComponent();

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('interacting with modal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('assigns the modal a unique ID', () => {
      const firstInstanceModalId = findModal().props('modalId');
      createComponent();
      const secondInstanceModalId = findModal().props('modalId');
      expect(firstInstanceModalId).not.toEqual(secondInstanceModalId);
    });

    describe('rendering form elements', () => {
      it('renders limit input and update limit button', () => {
        expect(findInput().exists()).toBe(true);
        expect(findUpdateLimitButton().exists()).toBe(true);
      });
    });
  });

  describe('update limit button', () => {
    beforeEach(() => {
      createComponent();
      findUpdateLimitButton().trigger('click');
    });

    it('shows a confirmation modal', () => {
      expect(glModalDirective).toHaveBeenCalled();
    });

    it('passes the correct attributes to modal primary action', () => {
      expect(findModal().props('actionPrimary')).toEqual({
        attributes: {
          variant: 'danger',
        },
        text: 'Confirm limits change',
      });
    });

    describe('changing limits', () => {
      describe('when input is valid', () => {
        it('emits limit-change event when modal is confirmed', () => {
          findInput().setValue(150);
          findModal().vm.$emit('primary');
          expect(wrapper.emitted('limit-change')).toStrictEqual([['150']]);
        });
      });

      describe('when input is invalid', () => {
        beforeEach(() => {
          findInput().setValue(-150);
          findModal().vm.$emit('primary');

          return nextTick();
        });

        it('does not emit limit-change event', () => {
          expect(wrapper.emitted('limit-change')).toBeUndefined();
        });

        it('shows a validation error', () => {
          expect(findAlert().text()).toEqual('Enter a valid number greater or equal to zero.');
        });

        it('clears any previous error message when resubmitting', async () => {
          expect(findAlert().exists()).toBe(true);

          findInput().setValue(10);
          findModal().vm.$emit('primary');
          await nextTick();

          expect(findAlert().exists()).toBe(false);
        });
      });
    });
  });

  describe('changelog', () => {
    it('renders <namespace-limits-changelog/>', () => {
      createComponent();
      expect(findChangelogComponent().exists()).toBe(true);
      expect(findChangelogComponent().props()).toEqual({ entries: [] });
    });
  });
});
