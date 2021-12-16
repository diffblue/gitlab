import { shallowMount } from '@vue/test-utils';
import SecurityDashboardLayout from 'ee/security_dashboard/components/shared/security_dashboard_layout.vue';
import SurveyRequestBanner from 'ee/security_dashboard/components/shared/survey_request_banner.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SbomBanner from 'ee/sbom_banner/components/app.vue';

describe('Security Dashboard Layout component', () => {
  let wrapper;

  const DummyComponent = {
    name: 'dummy-component-1',
    template: '<p>dummy component 1</p>',
  };

  const findDummyComponent = () => wrapper.findComponent(DummyComponent);
  const findTitle = () => wrapper.findByTestId('title');
  const findSurveyBanner = () => wrapper.findComponent(SurveyRequestBanner);
  const findSbomBanner = () => wrapper.findComponent(SbomBanner);

  const createWrapper = (slots, props = { showSbomSurvey: true }) => {
    wrapper = extendedWrapper(
      shallowMount(SecurityDashboardLayout, {
        provide: {
          sbomSurveySvgPath: '/',
        },
        propsData: {
          ...props,
        },
        slots,
      }),
    );
  };

  beforeEach(() => {
    window.gon = {
      features: {
        sbomSurvey: true,
      },
    };
  });

  afterEach(() => {
    wrapper.destroy();
    window.gon = {};
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

  describe('given a false showSbowmSurvey prop', () => {
    beforeEach(() => {
      createWrapper({}, { showSbomSurvey: false });
    });
    it('does not render the SBOM Banner component', () => {
      const sbomBanner = findSbomBanner();
      expect(sbomBanner.exists()).toBe(false);
    });
  });

  describe('given a true showSbowmSurvey prop', () => {
    beforeEach(() => {
      createWrapper({}, { showSbomSurvey: true });
    });
    it('does not render the SBOM Banner component', () => {
      const sbomBanner = findSbomBanner();
      expect(sbomBanner.exists()).toBe(true);
      expect(sbomBanner.props().sbomSurveySvgPath).toBe(wrapper.vm.sbomSurveySvgPath);
    });
  });
});
