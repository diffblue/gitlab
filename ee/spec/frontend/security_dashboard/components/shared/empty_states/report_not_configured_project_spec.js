import { GlButton, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ReportNotConfiguredProject from 'ee/security_dashboard/components/project/report_not_configured_project.vue';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

describe('Project report not configured component', () => {
  let wrapper;
  const emptyStateSvgPath = '/placeholder.svg';
  const securityConfigurationPath = '/configuration';
  const newVulnerabilityPath = '/vulnerability/new';

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ provide } = {}) => {
    wrapper = shallowMount(ReportNotConfiguredProject, {
      provide: {
        emptyStateSvgPath,
        securityConfigurationPath,
        newVulnerabilityPath,
        canAdminVulnerability: false,
        ...provide,
      },
    });
  };

  it('passes expected props to the GlEmptyState', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: ReportNotConfiguredProject.i18n.title,
      svgPath: emptyStateSvgPath,
      primaryButtonText: ReportNotConfiguredProject.i18n.primaryButtonText,
      primaryButtonLink: securityConfigurationPath,
      secondaryButtonText: ReportNotConfiguredProject.i18n.secondaryButtonText,
      secondaryButtonLink: DOC_PATH_SECURITY_CONFIGURATION,
      description: ReportNotConfiguredProject.i18n.description,
    });
  });

  describe.each`
    provide                                                      | expectedShow
    ${{ newVulnerabilityPath: '', canAdminVulnerability: true }} | ${false}
    ${{ newVulnerabilityPath, canAdminVulnerability: false }}    | ${false}
    ${{ newVulnerabilityPath, canAdminVulnerability: true }}     | ${true}
  `('should display or hide the button based on the condition', ({ provide, expectedShow }) => {
    beforeEach(() => {
      createComponent({ provide });
    });

    it(`shows the button: ${expectedShow}`, () => {
      expect(findButton().exists()).toBe(expectedShow);
    });
  });
});
