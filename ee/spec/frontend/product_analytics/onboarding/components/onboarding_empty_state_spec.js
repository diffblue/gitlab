import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import OnboardingEmptyState from 'ee/product_analytics/onboarding/components/onboarding_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';
import { EMPTY_STATE_I18N } from 'ee/product_analytics/onboarding/constants';

describe('OnboardingEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSetupBtn = () => wrapper.findByTestId('setup-btn');
  const findLearnMoreBtn = () => wrapper.findByTestId('learn-more-btn');

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(OnboardingEmptyState, {
      provide: {
        chartEmptyStateIllustrationPath: TEST_HOST,
      },
      propsData: {
        ...props,
      },
    });
  };

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the empty state with expected props', () => {
      const emptyState = findEmptyState();

      expect(emptyState.props()).toMatchObject({
        title: EMPTY_STATE_I18N.empty.title,
        svgPath: TEST_HOST,
      });
      expect(emptyState.text()).toContain(EMPTY_STATE_I18N.empty.description);
      expect(findSetupBtn().text()).toBe(EMPTY_STATE_I18N.empty.setUpBtnText);
      expect(findLearnMoreBtn().text()).toBe(EMPTY_STATE_I18N.empty.learnMoreBtnText);
      expect(findLearnMoreBtn().attributes('href')).toBe('/help/user/product_analytics/index');
    });

    it('should emit `initialize` when the setup button is clicked', () => {
      findSetupBtn().vm.$emit('click');

      expect(wrapper.emitted('initialize')).toStrictEqual([[]]);
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createWrapper({ loading: true });
    });

    it('should render the loading state', () => {
      const emptyState = findEmptyState();

      expect(emptyState.props()).toMatchObject({
        title: EMPTY_STATE_I18N.loading.title,
        svgPath: TEST_HOST,
      });
      expect(emptyState.text()).toContain(EMPTY_STATE_I18N.loading.description);
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render the buttons', () => {
      expect(findSetupBtn().exists()).toBe(false);
      expect(findLearnMoreBtn().exists()).toBe(false);
    });
  });
});
