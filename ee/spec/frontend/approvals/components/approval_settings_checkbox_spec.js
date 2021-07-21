import { GlFormCheckbox, GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ApprovalSettingsCheckbox from 'ee/approvals/components/approval_settings_checkbox.vue';
import { APPROVALS_HELP_PATH } from 'ee/approvals/constants';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { slugify } from '~/lib/utils/text_utility';

describe('ApprovalSettingsCheckbox', () => {
  const label = 'Foo';
  const anchor = 'bar-baz';
  const lockIconId = `approval-settings-checkbox-lock-icon-${slugify(label)}`;

  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ApprovalSettingsCheckbox, {
        propsData: { label, anchor, ...props },
        stubs: {
          GlFormCheckbox: stubComponent(GlFormCheckbox, {
            props: ['checked'],
          }),
          GlIcon,
          GlLink,
        },
      }),
    );
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findLink = () => wrapper.findComponent(GlLink);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLockIcon = () => wrapper.findByTestId('lock-icon');
  const findHelpIcon = () => wrapper.findByTestId('help-icon');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the label', () => {
      expect(findCheckbox().text()).toBe(label);
    });

    it('sets the correct help link', () => {
      expect(findLink().attributes('href')).toBe(`/help/${APPROVALS_HELP_PATH}#${anchor}`);
    });

    it('shows a help icon', () => {
      expect(findHelpIcon().props('name')).toBe('question-o');
    });
  });

  describe('value', () => {
    it('defaults to false when no value is given', () => {
      createWrapper();

      expect(findCheckbox().props('checked')).toBe(false);
    });

    it('sets the checkbox to `true` when a `true` value is given', () => {
      createWrapper({ value: true });

      expect(findCheckbox().props('checked')).toBe(true);
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

      it('does not render a lock icon', () => {
        expect(findLockIcon().exists()).toBe(false);
      });

      it('does not render a popover', () => {
        expect(findPopover().exists()).toBe(false);
      });

      it('the input is enabled', () => {
        expect(findCheckbox().attributes('disabled')).toBeUndefined();
      });
    });

    describe('when the setting is locked', () => {
      beforeEach(() => {
        createWrapper({ locked: true });
      });

      it('disables the input', () => {
        expect(findCheckbox().attributes('disabled')).toBe('disabled');
      });

      it('shows a lock icon', () => {
        expect(findLockIcon().props('name')).toBe('lock');
        expect(findLockIcon().attributes('id')).toBe(lockIconId);
      });

      it('shows a popover for the lock icon', () => {
        expect(findPopover().props('target')).toBe(lockIconId);
      });

      it('configures how and when the popover should show', () => {
        expect(findPopover().props()).toMatchObject({
          title: 'Setting enforced',
          triggers: 'hover focus',
          placement: 'top',
          container: 'viewport',
        });
      });

      it('when lockedText is set, then the popover content matches the lockedText', () => {
        const lockedText = 'Admin';
        createWrapper({ locked: true, lockedText });

        expect(findPopover().attributes('content')).toBe(lockedText);
      });

      it('when lockedText is not set, then the popover content is empty', () => {
        expect(findPopover().attributes('content')).toBe('');
      });
    });
  });
});
