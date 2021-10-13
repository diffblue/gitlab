import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import SubscriptionDetailsHistory from 'ee/admin/subscriptions/show/components/subscription_details_history.vue';
import { cloudLicenseText } from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { license, subscriptionHistory } from '../mock_data';

describe('Subscription Details History', () => {
  let wrapper;

  const findCurrentRow = () => wrapper.findByTestId('subscription-current');
  const findTableRows = () => wrapper.findAllByTestId('subscription-history-row');
  const cellFinder = (row) => (testId) => extendedWrapper(row).findByTestId(testId);
  const containsABadge = (row) => row.findComponent(GlBadge).exists();

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      mount(SubscriptionDetailsHistory, {
        propsData: {
          currentSubscriptionId: license.ULTIMATE.id,
          subscriptionList: subscriptionHistory,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has a current subscription row', () => {
      expect(findCurrentRow().exists()).toBe(true);
    });

    it('has the correct number of subscription rows', () => {
      expect(findTableRows()).toHaveLength(1);
    });

    it('has the correct license type', () => {
      expect(findCurrentRow().text()).toContain(cloudLicenseText);
      expect(findTableRows().at(0).text()).toContain('License file');
    });

    it('has a badge for the license type', () => {
      expect(findTableRows().wrappers.every(containsABadge)).toBe(true);
    });

    it('highlights the current subscription row', () => {
      expect(findCurrentRow().classes('gl-text-blue-500')).toBe(true);
    });

    it('does not highlight the other subscription row', () => {
      expect(findTableRows().at(0).classes('gl-text-blue-500')).toBe(false);
    });

    describe('cell data', () => {
      let findCellByTestid;

      beforeEach(() => {
        createComponent();
        findCellByTestid = cellFinder(findCurrentRow());
      });

      it.each`
        testId                      | key
        ${'name'}                   | ${'name'}
        ${'email'}                  | ${'email'}
        ${'company'}                | ${'company'}
        ${'starts-at'}              | ${'startsAt'}
        ${'starts-at'}              | ${'startsAt'}
        ${'expires-at'}             | ${'expiresAt'}
        ${'users-in-license-count'} | ${'usersInLicenseCount'}
      `('displays the correct value for the $testId cell', ({ testId, key }) => {
        const cellTestId = `subscription-cell-${testId}`;
        expect(findCellByTestid(cellTestId).text()).toBe(subscriptionHistory[0][key]);
      });

      it('displays the correct value for the type cell', () => {
        const cellTestId = `subscription-cell-type`;
        expect(findCellByTestid(cellTestId).text()).toBe(cloudLicenseText);
      });

      it('displays the correct value for the plan cell', () => {
        const cellTestId = `subscription-cell-plan`;
        expect(findCellByTestid(cellTestId).text()).toBe('Ultimate');
      });
    });
  });

  describe('with no data', () => {
    beforeEach(() => {
      createComponent({
        subscriptionList: [],
      });
    });

    it('has the correct number of rows', () => {
      expect(findTableRows()).toHaveLength(0);
    });
  });
});
