import { shallowMount } from '@vue/test-utils';
import ReportNotConfiguredOperational from 'ee/security_dashboard/components/shared/empty_states/report_not_configured_operational.vue';

describe('Operational report not configured component', () => {
  let wrapper;
  const operationalConfigurationPath = '/operational-configuration';
  const operationalEmptyStateSvgPath = '/operational-placeholder.svg';
  const operationalHelpPath = '/operational-help';

  const createComponent = (dashboardType = 'project') => {
    wrapper = shallowMount(ReportNotConfiguredOperational, {
      provide: {
        dashboardType,
        operationalConfigurationPath,
        operationalEmptyStateSvgPath,
        operationalHelpPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot for projects', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('matches the snapshot for groups', () => {
    createComponent('group');
    expect(wrapper.element).toMatchSnapshot();
  });

  it('matches the snapshot for instances', () => {
    createComponent('instance');
    expect(wrapper.element).toMatchSnapshot();
  });
});
