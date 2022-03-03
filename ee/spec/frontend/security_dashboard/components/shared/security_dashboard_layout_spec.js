import { shallowMount } from '@vue/test-utils';
import SecurityDashboardLayout from 'ee/security_dashboard/components/shared/security_dashboard_layout.vue';
import SurveyRequestBanner from 'ee/security_dashboard/components/shared/survey_request_banner.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('Security Dashboard Layout component', () => {
  let wrapper;

  const DummyComponent = {
    name: 'dummy-component-1',
    template: '<p>dummy component 1</p>',
  };

  const findDummyComponent = () => wrapper.findComponent(DummyComponent);
  const findTitle = () => wrapper.findByTestId('title');
  const findSurveyBanner = () => wrapper.findComponent(SurveyRequestBanner);

  const createWrapper = (slots) => {
    wrapper = extendedWrapper(shallowMount(SecurityDashboardLayout, { slots }));
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render the default slot and survey banner', () => {
    createWrapper({ default: DummyComponent });

    expect(findDummyComponent().exists()).toBe(true);
    expect(findTitle().exists()).toBe(true);
    expect(findSurveyBanner().exists()).toBe(true);
  });

  it('should render the empty-state slot and survey banner', () => {
    createWrapper({ 'empty-state': DummyComponent });

    expect(findDummyComponent().exists()).toBe(true);
    expect(findTitle().exists()).toBe(false);
    expect(findSurveyBanner().exists()).toBe(true);
  });

  it('should render the loading slot', () => {
    createWrapper({ loading: DummyComponent });

    expect(findDummyComponent().exists()).toBe(true);
    expect(findTitle().exists()).toBe(false);
    expect(findSurveyBanner().exists()).toBe(false);
  });
});
