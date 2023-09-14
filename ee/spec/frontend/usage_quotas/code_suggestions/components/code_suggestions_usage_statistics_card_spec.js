import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CodeSuggestionsUsageStatisticsCard from 'ee/usage_quotas/code_suggestions/components/code_suggestions_usage_statistics_card.vue';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';

describe('CodeSuggestionsUsageStatisticsCard', () => {
  let wrapper;

  const findCodeSuggestionsDescription = () => wrapper.findByTestId('code-suggestions-description');
  const findCodeSuggestionsInfo = () => wrapper.findByTestId('code-suggestions-info');
  const findUsageStatistics = () => wrapper.findComponent(UsageStatistics);
  const createComponent = (propsData) => {
    wrapper = shallowMountExtended(CodeSuggestionsUsageStatisticsCard, {
      propsData,
      stubs: {
        GlSprintf,
        UsageStatistics: {
          template: `
            <div>
                <slot name="actions"></slot>
                <slot name="description"></slot>
                <slot name="additional-info"></slot>
            </div>
            `,
        },
      },
    });

    return waitForPromises();
  };

  describe('with purchased Add-ons', () => {
    beforeEach(() => {
      return createComponent({ usageValue: 0, totalValue: 20 });
    });

    it('renders the description text', () => {
      expect(findCodeSuggestionsDescription().text()).toBe(
        `A user can be assigned a Code Suggestion seat only once each billable month.`,
      );
    });

    it('renders the info text', () => {
      expect(findCodeSuggestionsInfo().text()).toBe('Code Suggestions seats used');
    });

    it('passes the correct props to <usage-statistics>', () => {
      expect(findUsageStatistics().attributes()).toMatchObject({
        percentage: '0',
        'total-value': '20',
        'usage-value': '0',
      });
    });

    describe('with no purchased Add-ons', () => {
      beforeEach(() => {
        return createComponent({ usageValue: 0, totalValue: 0 });
      });

      it('does not render usage statistics', () => {
        expect(findUsageStatistics().exists()).toBe(false);
      });
    });

    describe('with assigned Add-ons', () => {
      beforeEach(() => {
        return createComponent({ usageValue: 5, totalValue: 20 });
      });

      it('passes the correct props to <usage-statistics>', () => {
        expect(findUsageStatistics().attributes()).toMatchObject({
          percentage: '25',
          'total-value': '20',
          'usage-value': '5',
        });
      });
    });
  });
});
