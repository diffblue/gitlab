import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  codeSuggestionsInfoLink,
  codeSuggestionsInfoText,
  codeSuggestionIntroDescriptionText,
  codeSuggestionsLearnMoreLink,
  learnMoreText,
} from 'ee/usage_quotas/seats/constants';
import CodeSuggestionsUsageStatisticsCard from 'ee/usage_quotas/seats/components/code_suggestions_usage_statistics_card.vue';

describe('CodeSuggestionsUsageStatisticsCard', () => {
  let wrapper;

  const findLearnMoreButton = () => wrapper.findByTestId('learn-more');
  const findCodeSuggestionsDescription = () => wrapper.findByTestId('code-suggestions-description');
  const findCodeSuggestionsInfo = () => wrapper.findByTestId('code-suggestions-info');
  const findCodeSuggestionsInfoLink = () => wrapper.findByTestId('code-suggestions-info-link');
  const createComponent = () => {
    wrapper = shallowMountExtended(CodeSuggestionsUsageStatisticsCard, {
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
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });

  describe('`Learn more` button', () => {
    it('renders the text', () => {
      expect(findLearnMoreButton().text()).toBe(learnMoreText);
    });

    it('provides the correct href', () => {
      expect(findLearnMoreButton().attributes('href')).toBe(codeSuggestionsLearnMoreLink);
    });
  });

  it('renders the description text', () => {
    expect(findCodeSuggestionsDescription().text()).toBe(codeSuggestionIntroDescriptionText);
  });

  it('renders the info text', () => {
    expect(findCodeSuggestionsInfo().text()).toMatchInterpolatedText(codeSuggestionsInfoText);
  });

  it('renders the info link', () => {
    expect(findCodeSuggestionsInfoLink().attributes('href')).toBe(codeSuggestionsInfoLink);
  });
});
