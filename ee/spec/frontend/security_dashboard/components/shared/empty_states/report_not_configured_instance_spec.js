import { shallowMount } from '@vue/test-utils';
import ReportNotConfiguredInstance from 'ee/security_dashboard/components/shared/empty_states/report_not_configured_instance.vue';

describe('Instance report not configured component', () => {
  let wrapper;
  const instanceDashboardSettingsPath = '/path/to/dashboard/settings';
  const dashboardDocumentation = '/path/to/dashboard/documentation';
  const emptyStateSvgPath = '/placeholder.svg';

  const createWrapper = () =>
    shallowMount(ReportNotConfiguredInstance, {
      provide: {
        dashboardDocumentation,
        emptyStateSvgPath,
        instanceDashboardSettingsPath,
      },
    });

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches snapshot', () => {
    expect(wrapper.html()).toMatchSnapshot();
  });
});
