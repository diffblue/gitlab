import { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from 'ee/api';
import GroupSelect from 'ee/ldap/components/group_select.vue';
import { i18n } from 'ee/ldap/components/constants';

jest.mock('ee/api', () => ({
  ldapGroups: jest.fn(),
}));

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

describe('GroupSelect', () => {
  let wrapper;
  const providerElement = document.createElement('select');

  const createComponent = ({ props = {}, apiSpy } = {}) => {
    if (!apiSpy) {
      Api.ldapGroups.mockResolvedValue([{ cn: 'test' }]);
    }

    wrapper = mountExtended(GroupSelect, {
      propsData: { providerElement, ...props },
    });
  };

  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findScreenReaderHelper = () => wrapper.find('.gl-sr-only');
  const findHiddenInput = () => wrapper.find('input[type=hidden]');

  describe('default', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not display the alert', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('retrieves groups after the component is mounted', () => {
      expect(Api.ldapGroups).toHaveBeenCalledTimes(1);
    });

    it('updates the hidden input value when a group is selected', async () => {
      const group = 'test';
      findCollapsibleListbox().vm.$emit('select', group);
      await nextTick();
      expect(findHiddenInput().attributes('value')).toBe(group);
    });

    it(`updates the listbox's 'toggleText' prop when a group is selected`, async () => {
      expect(findCollapsibleListbox().props('toggleText')).toBe(i18n.placeholder);
      const group = 'test';
      findCollapsibleListbox().vm.$emit('select', group);
      await nextTick();
      expect(findCollapsibleListbox().props('toggleText')).toBe(group);
    });

    it('retrieves groups based on a user search query', async () => {
      expect(Api.ldapGroups).toHaveBeenCalledTimes(1);
      Api.ldapGroups.mockResolvedValue([{ cn: '3' }]);
      findCollapsibleListbox().vm.$emit('search', '3');
      await nextTick();
      await waitForPromises();

      expect(findCollapsibleListbox().props('items')).toEqual([{ cn: '3', text: '3', value: '3' }]);
      expect(Api.ldapGroups).toHaveBeenCalledTimes(2);
    });

    it('deselects a selected value on provider element change', async () => {
      const group = 'test';
      findCollapsibleListbox().vm.$emit('select', group);
      await nextTick();
      expect(findHiddenInput().attributes('value')).toBe(group);
      providerElement.dispatchEvent(new Event('change'));
      await nextTick();
      expect(findHiddenInput().attributes('value')).toBe('');
    });
  });

  describe('searching', () => {
    it('toggles the searching spinner', async () => {
      createComponent();
      await nextTick();
      expect(findCollapsibleListbox().props('searching')).toBe(true);

      await waitForPromises();
      expect(findCollapsibleListbox().props('searching')).toBe(false);
    });

    it('displays the search summary text', async () => {
      createComponent();
      await nextTick();
      expect(findScreenReaderHelper().text()).toBe('0 groups found');
    });
  });

  describe('error', () => {
    beforeEach(() => {
      createComponent({ apiSpy: Api.ldapGroups.mockRejectedValue() });
    });

    it('does not display the searching spinner', () => {
      expect(findCollapsibleListbox().props('searching')).toBe(false);
    });

    it('displays the alert', () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
    });

    it('dismisses the error on a new group search', () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(mockAlertDismiss).toHaveBeenCalledTimes(0);

      jest.spyOn(Api, 'ldapGroups').mockResolvedValue([]);
      findCollapsibleListbox().vm.$emit('search', '3');
      jest.runOnlyPendingTimers();

      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
    });
  });
});
