import { GlFormRadio } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ApprovalSettingsRadio from 'ee/approvals/components/approval_settings_radio.vue';
import ApprovalSettingsLockedIcon from 'ee/approvals/components/approval_settings_locked_icon.vue';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('ApprovalSettingsRadio', () => {
  const label = 'Foo';
  const name = 'approval-removal-setting';
  const lockedText = 'locked-text';
  const value = 'value';

  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ApprovalSettingsRadio, {
        propsData: { label, name, lockedText, value, ...props },
        stubs: {
          GlFormRadio: stubComponent(GlFormRadio, {
            props: ['checked'],
          }),
        },
      }),
    );
  };

  const findRadio = () => wrapper.findComponent(GlFormRadio);
  const findLockedIcon = () => wrapper.findComponent(ApprovalSettingsLockedIcon);

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the label', () => {
      expect(findRadio().text()).toContain(label);
    });
  });

  describe('locked', () => {
    describe('when the setting is not locked', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('the input is enabled', () => {
        expect(findRadio().attributes('disabled')).toBeUndefined();
      });

      it('does not render locked_icon', () => {
        expect(findLockedIcon().exists()).toBe(false);
      });
    });

    describe('when the setting is locked', () => {
      beforeEach(() => {
        createWrapper({ locked: true });
      });

      it('disables the input', () => {
        expect(findRadio().attributes('disabled')).toBeDefined();
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
});
