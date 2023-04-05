import { GlFormCheckbox } from '@gitlab/ui';

import ApprovalSettingsCheckbox from 'ee/approvals/components/approval_settings_checkbox.vue';
import ApprovalSettingsLockedIcon from 'ee/approvals/components/approval_settings_locked_icon.vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';

describe('ApprovalSettingsCheckbox', () => {
  const label = 'Foo';
  const lockedText = 'locked-text';

  let wrapper;

  const createWrapper = ({ mountFn = shallowMountExtended, props = {}, slots = {} } = {}) => {
    wrapper = mountFn(ApprovalSettingsCheckbox, {
      propsData: { label, lockedText, ...props },
      slots,
    });
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findLockedIcon = () => wrapper.findComponent(ApprovalSettingsLockedIcon);

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the label', () => {
      expect(findCheckbox().text()).toContain(label);
    });
  });

  describe('checked', () => {
    it('defaults to false when no checked value is given', () => {
      createWrapper();

      expect(findCheckbox().attributes('checked')).toBeUndefined();
    });

    it('sets the checkbox to truthy value when checked is `true`', () => {
      createWrapper({ props: { checked: true } });

      expect(findCheckbox().attributes('checked')).toBeDefined();
    });

    it('emits an input event when the checkbox is changed', async () => {
      createWrapper();

      await findCheckbox().vm.$emit('input', true);

      expect(wrapper.emitted('input')[0]).toStrictEqual([true]);
    });
  });

  describe('locked', () => {
    describe('when the setting is not locked', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('the input is enabled', () => {
        expect(findCheckbox().attributes('disabled')).toBeUndefined();
      });

      it('does not render locked_icon', () => {
        expect(findLockedIcon().exists()).toBe(false);
      });
    });

    describe('when the setting is locked', () => {
      beforeEach(() => {
        createWrapper({ props: { locked: true } });
      });

      it('disables the input', () => {
        expect(findCheckbox().attributes('disabled')).toBeDefined();
      });

      it('renders locked_icon', () => {
        expect(findLockedIcon().exists()).toBe(true);
      });

      it('passes expected props to locked_icon', () => {
        expect(findLockedIcon().props('label')).toBe(label);
        expect(findLockedIcon().props('lockedText')).toBe(lockedText);
      });
    });
  });

  describe('data-qa-selector', () => {
    it('defaults to undefined when no checkboxQaSelector value is given', () => {
      createWrapper();

      expect(findCheckbox().attributes('data-qa-selector')).toBeUndefined();
    });

    it('sets the data-qa-selector when checkboxQaSelector is given', () => {
      createWrapper({ props: { checkboxQaSelector: 'test-checkbox' } });

      expect(findCheckbox().attributes('data-qa-selector')).toBe('test-checkbox');
    });
  });

  describe('#slot', () => {
    it('should render a default slot', () => {
      const slotContent = 'test slot content';
      createWrapper({
        mountFn: mountExtended,
        slots: {
          help: slotContent,
        },
      });

      expect(wrapper.text()).toContain(slotContent);
    });
  });
});
