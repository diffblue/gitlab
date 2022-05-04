import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ReportNotConfiguredProject from 'ee/security_dashboard/components/shared/empty_states/report_not_configured_project.vue';

describe('Project report not configured component', () => {
  let wrapper;
  const emptyStateSvgPath = '/placeholder.svg';
  const securityConfigurationPath = '/configuration';
  const securityDashboardHelpPath = '/help';
  const newVulnerabilityPath = '/vulnerability/new';

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ provide } = {}) => {
    wrapper = shallowMount(ReportNotConfiguredProject, {
      provide: {
        emptyStateSvgPath,
        securityConfigurationPath,
        securityDashboardHelpPath,
        newVulnerabilityPath,
        ...provide,
      },
    });
  };

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

  describe('when button is shown', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          canAdminVulnerability: true,
        },
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });
});
