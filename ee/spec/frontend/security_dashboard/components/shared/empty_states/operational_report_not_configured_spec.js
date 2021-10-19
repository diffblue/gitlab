import { shallowMount } from '@vue/test-utils';
import OperationalReportNotConfigured from 'ee/security_dashboard/components/shared/empty_states/operational_report_not_configured.vue';

describe('reports not configured empty state', () => {
  let wrapper;
  const operationalConfigurationPath = '/operational-configuration';
  const operationalEmptyStateSvgPath = '/operational-placeholder.svg';
  const operationalHelpPath = '/operational-help';

  const createComponent = (dashboardType = 'project') => {
    wrapper = shallowMount(OperationalReportNotConfigured, {
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
