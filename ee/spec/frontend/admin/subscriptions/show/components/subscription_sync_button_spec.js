import { GlButton, GlIcon, GlLoadingIcon, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import SubscriptionSyncButton from 'ee/admin/subscriptions/show/components/subscription_sync_button.vue';
import * as initialStore from 'ee/admin/subscriptions/show/store/';
import createState from 'ee/admin/subscriptions/show/store/state';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { syncButtonTexts, SYNC_BUTTON_ID } from 'ee/admin/subscriptions/show/constants';

const subscriptionSyncPath = '/sync/path/';

describe('Subscription Sync Button', () => {
  const createStore = (options = {}) => {
    const {
      syncMock = jest.fn(),
      initialState = createState({ licenseRemovePath: '', subscriptionSyncPath }),
    } = options;
    return new Vuex.Store({
      licenseRemovalPath: '',
      subscriptionSyncPath: '',
      ...initialStore,
      actions: {
        syncSubscription: syncMock,
      },
      state: {
        ...initialState,
      },
    });
  };

  const createComponent = (options = {}) => {
    const { store = createStore() } = options;

    return extendedWrapper(
      shallowMount(SubscriptionSyncButton, {
        store,
        provide: { subscriptionSyncPath },
      }),
    );
  };

  const findButton = (wrapper) => wrapper.findComponent(GlButton);
  const findSyncIcon = (wrapper) => wrapper.findComponent(GlIcon);
  const findLoadingIcon = (wrapper) => wrapper.findComponent(GlLoadingIcon);
  const findPopover = (wrapper) => wrapper.findComponent(GlPopover);

  describe('button', () => {
    let wrapper;
    let syncButton;

    beforeEach(() => {
      wrapper = createComponent();
      syncButton = findButton(wrapper);
    });

    it('displays with default variant', () => {
      expect(syncButton.props('variant')).toBe('default');
    });

    it('displays with tertiary category', () => {
      expect(syncButton.props('category')).toBe('tertiary');
    });

    it('displays with small size', () => {
      expect(syncButton.props('size')).toBe('small');
    });

    it('displays correct icon', () => {
      expect(findSyncIcon(wrapper).exists()).toBe(true);
      expect(findSyncIcon(wrapper).props('name')).toBe('retry');
      expect(findLoadingIcon(wrapper).exists()).toBe(false);
    });

    it('contains an aria-label', () => {
      expect(syncButton.attributes('aria-label')).toBe(syncButtonTexts.syncSubscriptionButtonText);
    });

    it('has a popover', () => {
      expect(findPopover(wrapper).exists()).toBe(true);
    });

    it('does not display any text', () => {
      expect(syncButton.text()).toBe('');
    });
  });

  describe('popover', () => {
    let wrapper;
    let popover;

    beforeEach(() => {
      wrapper = createComponent();
      popover = findPopover(wrapper);
    });

    it('displays to the right', () => {
      expect(popover.props('placement')).toBe('right');
    });

    it('displays correct text', () => {
      expect(popover.attributes('content')).toContain(syncButtonTexts.syncSubscriptionTooltipText);
    });

    it('targets the button', () => {
      expect(popover.props('target')).toBe(SYNC_BUTTON_ID);
    });
  });

  describe('on click', () => {
    const syncSpy = jest.fn();
    let wrapper;

    beforeEach(() => {
      const store = createStore({ syncMock: syncSpy });
      wrapper = createComponent({ store });
    });

    it('triggers syncSubscription action', () => {
      findButton(wrapper).vm.$emit('click');

      expect(syncSpy).toHaveBeenCalled();
    });
  });

  describe('when has async activity', () => {
    let wrapper;

    beforeEach(() => {
      const initialState = createState({
        licenseRemovePath: '',
        subscriptionSyncPath,
        hasAsyncActivity: true,
      });
      const store = createStore({ initialState });
      wrapper = createComponent({ store });
    });

    it('disables the sync button', () => {
      expect(findButton(wrapper).props('disabled')).toBe(true);
    });
    it('hides a popover', () => {
      expect(findPopover(wrapper).exists()).toBe(false);
    });

    it('displays correct icon', () => {
      expect(findLoadingIcon(wrapper).exists()).toBe(true);
      expect(findSyncIcon(wrapper).exists()).toBe(false);
    });
  });
});
