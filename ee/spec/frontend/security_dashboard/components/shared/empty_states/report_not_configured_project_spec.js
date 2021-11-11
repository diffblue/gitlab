import { shallowMount } from '@vue/test-utils';
import ReportNotConfiguredProject from 'ee/security_dashboard/components/shared/empty_states/report_not_configured_project.vue';

describe('Project report not configured component', () => {
  let wrapper;
  const emptyStateSvgPath = '/placeholder.svg';
  const securityConfigurationPath = '/configuration';
  const securityDashboardHelpPath = '/help';

  const createComponent = () => {
    wrapper = shallowMount(ReportNotConfiguredProject, {
      provide: {
        emptyStateSvgPath,
        securityConfigurationPath,
        securityDashboardHelpPath,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('matches snapshot', () => {
    expect(wrapper.html()).toMatchSnapshot();
  });
});
