import { GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import addOnPurchaseQuery from 'ee/usage_quotas/graphql/queries/get_add_on_purchase_query.graphql';
import {
  codeSuggestionsAssignedDescriptionText,
  codeSuggestionsInfoLink,
  codeSuggestionsInfoText,
  codeSuggestionsIntroDescriptionText,
  codeSuggestionsLearnMoreLink,
  learnMoreText,
} from 'ee/usage_quotas/seats/constants';
import CodeSuggestionsUsageStatisticsCard from 'ee/usage_quotas/seats/components/code_suggestions_usage_statistics_card.vue';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import { assignedAddonData, noAssignedAddonData, noPurchasedAddonData } from '../mock_data';

Vue.use(VueApollo);

describe('CodeSuggestionsUsageStatisticsCard', () => {
  let wrapper;

  const fullPath = 'namespace/full-path';

  const assignedAddonDataHandler = jest.fn().mockResolvedValue(assignedAddonData);
  const noAssignedAddonDataHandler = jest.fn().mockResolvedValue(noAssignedAddonData);
  const noPurchasedAddonDataHandler = jest.fn().mockResolvedValue(noPurchasedAddonData);

  const createMockApolloProvider = (handler = noPurchasedAddonDataHandler) =>
    createMockApollo([[addOnPurchaseQuery, handler]]);

  const findCodeSuggestionsDescription = () => wrapper.findByTestId('code-suggestions-description');
  const findCodeSuggestionsInfo = () => wrapper.findByTestId('code-suggestions-info');
  const findCodeSuggestionsInfoLink = () => wrapper.findByTestId('code-suggestions-info-link');
  const findLearnMoreButton = () => wrapper.findByTestId('learn-more');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findUsageStatistics = () => wrapper.findComponent(UsageStatistics);
  const createComponent = ({ handler } = {}) => {
    wrapper = shallowMountExtended(CodeSuggestionsUsageStatisticsCard, {
      apolloProvider: createMockApolloProvider(handler),
      provide: { fullPath },
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

  it('renders the component', async () => {
    await createComponent();

    expect(wrapper.exists()).toBe(true);
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`renders <skeleton-loader>`, () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it(`does not render <usage-statistics>`, () => {
      expect(findUsageStatistics().exists()).toBe(false);
    });

    it('does not render the description', () => {
      expect(findCodeSuggestionsDescription().exists()).toBe(false);
    });

    it('does not render the info text', () => {
      expect(findCodeSuggestionsInfo().exists()).toBe(false);
    });
  });

  describe('with purchased Add-ons', () => {
    beforeEach(() => {
      return createComponent({ handler: noAssignedAddonDataHandler });
    });

    it('renders the description text', () => {
      expect(findCodeSuggestionsDescription().text()).toBe(codeSuggestionsAssignedDescriptionText);
    });

    it('renders the info text', () => {
      expect(findCodeSuggestionsInfo().text()).toMatchInterpolatedText(codeSuggestionsInfoText);
    });

    it('renders the info link', () => {
      expect(findCodeSuggestionsInfoLink().attributes('href')).toBe(codeSuggestionsInfoLink);
    });

    it('passes the correct props to <usage-statistics>', () => {
      expect(findUsageStatistics().attributes()).toMatchObject({
        percentage: '0',
        'total-value': '20',
        'usage-value': '0',
      });
    });

    describe('with assigned Add-ons', () => {
      beforeEach(() => {
        return createComponent({ handler: assignedAddonDataHandler });
      });

      it('renders the description text', () => {
        expect(findCodeSuggestionsDescription().text()).toBe(
          codeSuggestionsAssignedDescriptionText,
        );
      });

      it('does not render `Learn more` button', () => {
        expect(findLearnMoreButton().exists()).toBe(false);
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

  describe('with no statistics', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('renders the description text', () => {
      expect(findCodeSuggestionsDescription().text()).toBe(codeSuggestionsIntroDescriptionText);
    });

    it('renders the info text', () => {
      expect(findCodeSuggestionsInfo().text()).toMatchInterpolatedText(codeSuggestionsInfoText);
    });

    it('renders the info link', () => {
      expect(findCodeSuggestionsInfoLink().attributes('href')).toBe(codeSuggestionsInfoLink);
    });

    describe(`with <usage-statistics>`, () => {
      it('passes the correct props', () => {
        expect(findUsageStatistics().exists()).toBe(false);
      });
    });

    describe('`Learn more` button', () => {
      it('renders the text', () => {
        expect(findLearnMoreButton().text()).toBe(learnMoreText);
      });

      it('provides the correct href', () => {
        expect(findLearnMoreButton().attributes('href')).toBe(codeSuggestionsLearnMoreLink);
      });
    });
  });
});
