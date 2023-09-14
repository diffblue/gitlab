import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import CodeSuggestionsInfoCard from 'ee/usage_quotas/code_suggestions/components/code_suggestions_info_card.vue';

describe('CodeSuggestionsInfoCard', () => {
  let wrapper;

  const findCodeSuggestionsDescription = () => wrapper.findByTestId('description');
  const findCodeSuggestionsLearnMoreLink = () => wrapper.findComponent(GlLink);
  const findCodeSuggestionsInfoTitle = () => wrapper.findByTestId('title');
  const createComponent = () => {
    wrapper = shallowMountExtended(CodeSuggestionsInfoCard, {
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
    return createComponent();
  });

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('renders the description text', () => {
    expect(findCodeSuggestionsDescription().text()).toBe(
      "Code Suggestions uses generative AI to suggest code while you're developing.",
    );
  });

  it('renders the learn more link', () => {
    expect(findCodeSuggestionsLearnMoreLink().attributes('href')).toBe(
      `${PROMO_URL}/solutions/code-suggestions/`,
    );
  });

  it('renders the title text', () => {
    expect(findCodeSuggestionsInfoTitle().text()).toBe('Code Suggestions add-on');
  });
});
