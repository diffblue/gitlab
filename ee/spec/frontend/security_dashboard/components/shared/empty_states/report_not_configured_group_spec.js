import { shallowMount } from '@vue/test-utils';
import ReportNotConfiguredGroup from 'ee/security_dashboard/components/shared/empty_states/report_not_configured_group.vue';

describe('Group report not configured component', () => {
  let wrapper;
  const dashboardDocumentation = '/path/to/dashboard/documentation';
  const emptyStateSvgPath = '/placeholder.svg';

  const createWrapper = () =>
    shallowMount(ReportNotConfiguredGroup, {
      provide: {
        dashboardDocumentation,
        emptyStateSvgPath,
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
