import { GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import SubscriptionDetailsTable from 'ee/admin/subscriptions/show/components/subscription_details_table.vue';
import { detailsLabels } from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

const licenseDetails = [
  {
    detail: 'expiresAt',
    value: 'in 1 year',
  },
  {
    detail: 'lastSync',
    value: 'just now',
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
  const hasClass = (className) => (w) => w.classes(className);
  const isNotLastSyncRow = (w) => w.attributes('data-testid') !== 'row-lastsync';

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      mount(SubscriptionDetailsTable, { propsData: { details: licenseDetails, ...props } }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with content', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the correct number of rows', () => {
      expect(findLabelCells()).toHaveLength(2);
      expect(findContentCells()).toHaveLength(2);
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
  });

  describe('with copy-able detail', () => {
    beforeEach(() => {
      createComponent({
        details: [
          {
            detail: 'id',
            value: 13,
          },
        ],
      });
    });

    it('shows a clipboard button', () => {
      expect(findClipboardButton().exists()).toBe(true);
    });

    it('passes the text to the clipboard', () => {
      expect(findClipboardButton().props('text')).toBe('13');
    });
  });

  describe('subscription sync state', () => {
    it('when the sync succeeded', () => {
      createComponent({ syncDidFail: false });

      expect(findLastSyncRow().classes('gl-text-gray-800')).toBe(true);
    });

    describe('when the sync failed', () => {
      beforeEach(() => {
        createComponent({ syncDidFail: true });
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
      createComponent({ details: [] });

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });
});
