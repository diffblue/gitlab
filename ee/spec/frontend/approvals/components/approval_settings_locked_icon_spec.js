import { GlIcon, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ApprovalSettingsLockedIcon from 'ee/approvals/components/approval_settings_locked_icon.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { slugify } from '~/lib/utils/text_utility';

describe('ApprovalSettingsLockedIcon', () => {
  const label = 'Foo';
  const lockIconId = `approval-settings-lock-icon-${slugify(label)}`;

  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ApprovalSettingsLockedIcon, {
        propsData: { label, ...props },
        stubs: {
          GlIcon,
        },
      }),
    );
  };

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLockIcon = () => wrapper.findByTestId('lock-icon');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper();
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
