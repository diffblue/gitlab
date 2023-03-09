import { GlBadge, GlIcon, GlTooltip } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import SubscriptionDetailsHistory from 'ee/admin/subscriptions/show/components/subscription_details_history.vue';
import { detailsLabels, onlineCloudLicenseText } from 'ee/admin/subscriptions/show/constants';
import { getLicenseTypeLabel } from 'ee/admin/subscriptions/show/utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { license, subscriptionFutureHistory, subscriptionPastHistory } from '../mock_data';

const subscriptionList = [...subscriptionFutureHistory, ...subscriptionPastHistory];
const currentSubscriptionIndex = subscriptionFutureHistory.length;

describe('Subscription Details History', () => {
  let wrapper;

  const findTableRows = () => wrapper.findAllByTestId('subscription-history-row');
  const findCurrentRow = () => findTableRows().at(currentSubscriptionIndex);
  const cellFinder = (row) => (testId) => extendedWrapper(row).findByTestId(testId);
  const containsABadge = (row) => row.findComponent(GlBadge).exists();
  const containsATooltip = (row) => row.findComponent(GlTooltip).exists();
  const findIcon = (row) => row.findComponent(GlIcon);

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      mount(SubscriptionDetailsHistory, {
        propsData: {
          currentSubscriptionId: license.ULTIMATE.id,
          subscriptionList,
          ...props,
        },
      }),
    );
  };

  describe('with data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has a current subscription row', () => {
      expect(findCurrentRow().exists()).toBe(true);
    });

    it('has the correct number of subscription rows', () => {
      expect(findTableRows()).toHaveLength(subscriptionList.length);
    });

    it('has the correct license type', () => {
      expect(findCurrentRow().text()).toContain(onlineCloudLicenseText);
      expect(findTableRows().at(-1).text()).toContain('Legacy license');
    });

    it('has a badge for the license type', () => {
      expect(findTableRows().wrappers.every(containsABadge)).toBe(true);
    });

    it('has a tooltip to display company and email fields', () => {
      expect(findTableRows().wrappers.every(containsATooltip)).toBe(true);
    });

    it('has an information icon with tabindex', () => {
      findTableRows().wrappers.forEach((row) => {
        const icon = findIcon(row);
        expect(icon.props('name')).toBe('information-o');
        expect(icon.attributes('tabindex')).toBe('0');
      });
    });

    it('highlights the current subscription row', () => {
      expect(findCurrentRow().classes('gl-text-blue-500')).toBe(true);
    });

    it('does not highlight the other subscription row', () => {
      expect(findTableRows().at(0).classes('gl-text-blue-500')).toBe(false);
    });

    describe.each(Object.entries(subscriptionList))('cell data index=%#', (index, subscription) => {
      let findCellByTestid;

      beforeEach(() => {
        createComponent();
        findCellByTestid = cellFinder(findTableRows().at(index));
      });

      it.each`
        testId                      | key
        ${'starts-at'}              | ${'startsAt'}
        ${'expires-at'}             | ${'expiresAt'}
        ${'users-in-license-count'} | ${'usersInLicenseCount'}
      `('displays the correct value for the $testId cell', ({ testId, key }) => {
        const cellTestId = `subscription-cell-${testId}`;
        const value = subscription[key] || '-';
        expect(findCellByTestid(cellTestId).text()).toBe(value);
      });

      it('displays the name field with tooltip', () => {
        const cellTestId = 'subscription-cell-name';
        const text = findCellByTestid(cellTestId).text();
        expect(text).toContain(subscription.name);
        expect(text).toContain(`(${subscription.company})`);
        expect(text).toContain(subscription.email);
      });

      it('displays sr-only element for screen readers', () => {
        const testId = 'subscription-history-sr-only';
        const text = findCellByTestid(testId).text();
        expect(text).not.toContain(subscription.name);
        expect(text).toContain(`(${detailsLabels.company}: ${subscription.company})`);
        expect(text).toContain(`${detailsLabels.email}: ${subscription.email}`);
      });

      it('displays the correct value for the type cell', () => {
        const cellTestId = `subscription-cell-type`;
        expect(findCellByTestid(cellTestId).text()).toBe(getLicenseTypeLabel(subscription.type));
      });

      it('displays the correct value for the plan cell', () => {
        const cellTestId = `subscription-cell-plan`;
        expect(findCellByTestid(cellTestId).text()).toBe(
          capitalizeFirstCharacter(subscription.plan),
        );
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
