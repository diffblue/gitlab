import { GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vuex from 'vuex';
import SubscriptionDetailsTable from 'ee/admin/subscriptions/show/components/subscription_details_table.vue';
import SubscriptionSyncButton from 'ee/admin/subscriptions/show/components/subscription_sync_button.vue';
import { detailsLabels, subscriptionTypes } from 'ee/admin/subscriptions/show/constants';
import * as initialStore from 'ee/admin/subscriptions/show/store/';
import createState from 'ee/admin/subscriptions/show/store/state';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

const syncDetails = {
  detail: 'lastSync',
  value: 'A date',
};

const licenseDetails = [
  {
    detail: 'expiresAt',
    value: 'in 1 year',
  },
  {
    detail: 'lastSync',
    value: 'just now',
  },
  {
    detail: 'email',
  },
];

const hasFontWeightBold = (wrapper) => wrapper.classes('gl-font-weight-bold');

describe('Subscription Details Table', () => {
  let wrapper;

  const findAllRows = () => wrapper.findAll('tbody > tr');
  const findContentCells = () => wrapper.findAllByTestId('details-content');
  const findLabelCells = () => wrapper.findAllByTestId('details-label');
  const findLastSyncRow = () => wrapper.findByTestId('row-lastsync');
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findSyncButton = () => wrapper.findComponent(SubscriptionSyncButton);

  const hasClass = (className) => (w) => w.classes(className);
  const isNotLastSyncRow = (w) => w.attributes('data-testid') !== 'row-lastsync';

  const createStore = (options = {}) => {
    const {
      didSyncFail,
      initialState = createState({ licenseRemovePath: '', subscriptionSyncPath: '' }),
    } = options;
    return new Vuex.Store({
      ...initialStore,
      getters: {
        didSyncFail: () => didSyncFail,
      },
      state: {
        ...initialState,
      },
    });
  };

  const createComponent = ({ store = createStore(), props } = {}) => {
    wrapper = extendedWrapper(
      mount(SubscriptionDetailsTable, {
        store,
        propsData: {
          details: licenseDetails,
          subscriptionType: subscriptionTypes.ONLINE_CLOUD,
          ...props,
        },
        provide: { subscriptionSyncPath: '' },
      }),
    );
  };

  describe('with content', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the correct number of rows', () => {
      expect(findLabelCells()).toHaveLength(licenseDetails.length);
      expect(findContentCells()).toHaveLength(licenseDetails.length);
    });

    it('displays the correct content for rows', () => {
      expect(findLabelCells().at(0).text()).toBe(`${detailsLabels.expiresAt}:`);
      expect(findContentCells().at(0).text()).toBe(licenseDetails[0].value);
    });

    it('displays the labels in bold', () => {
      expect(findLabelCells().wrappers.every(hasFontWeightBold)).toBe(true);
    });

    it('does not show a clipboard button', () => {
      expect(findClipboardButton().exists()).toBe(false);
    });

    it('shows the default row color', () => {
      expect(findLastSyncRow().classes('gl-text-gray-800')).toBe(true);
    });

    it('displays a dash for empty values', () => {
      expect(findLabelCells().at(2).text()).toBe(`${detailsLabels.email}:`);
      expect(findContentCells().at(2).text()).toBe('-');
    });
  });

  describe('with sync detail', () => {
    beforeEach(() => {
      createComponent({
        props: {
          details: [syncDetails],
        },
      });
    });

    it('shows the subscription sync button', () => {
      expect(findSyncButton().exists()).toBe(true);
    });
  });

  describe('with copy-able detail', () => {
    beforeEach(() => {
      createComponent({
        props: {
          details: [
            {
              detail: 'id',
              value: 13,
            },
          ],
        },
      });
    });

    it('shows a clipboard button', () => {
      expect(findClipboardButton().exists()).toBe(true);
    });

    it('passes the text to the clipboard', () => {
      expect(findClipboardButton().props('text')).toBe('13');
    });
  });

  describe('with lastSync detail', () => {
    it('shows the subscription sync button', () => {
      createComponent({ props: { details: [syncDetails] } });
      expect(findSyncButton().exists()).toBe(true);
    });

    it('hides the subscription sync button for offline cloud license', () => {
      createComponent({
        props: {
          details: [syncDetails],
          subscriptionType: subscriptionTypes.OFFLINE_CLOUD,
        },
      });

      expect(findSyncButton().exists()).toBe(false);
    });

    it('hides the subscription sync button for legacy license', () => {
      createComponent({
        props: {
          details: [syncDetails],
          subscriptionType: subscriptionTypes.LEGACY_LICENSE,
        },
      });

      expect(findSyncButton().exists()).toBe(false);
    });
  });

  describe('subscription sync state', () => {
    it('when the sync succeeded', () => {
      const store = createStore({ didSyncFail: false });
      createComponent({ store });

      expect(findLastSyncRow().classes('gl-text-gray-800')).toBe(true);
    });

    describe('when the sync failed', () => {
      beforeEach(() => {
        const store = createStore({ didSyncFail: true });
        createComponent({ store });
      });

      it('shows the highlighted color for the last sync row', () => {
        expect(findLastSyncRow().classes('gl-text-red-500')).toBe(true);
      });

      it('shows the default row color for all other rows', () => {
        const allButLastSync = findAllRows().wrappers.filter(isNotLastSyncRow);

        expect(allButLastSync.every(hasClass('gl-text-gray-800'))).toBe(true);
      });
    });
  });

  describe('with no content', () => {
    it('displays a loader', () => {
      createComponent({ props: { details: [] } });

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });
});
