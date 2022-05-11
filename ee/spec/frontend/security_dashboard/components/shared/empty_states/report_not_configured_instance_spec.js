import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import ReportNotConfiguredInstance from 'ee/security_dashboard/components/instance/report_not_configured_instance.vue';

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

  it('passes expected props to the GlEmptyState', () => {
    expect(wrapper.find(GlEmptyState).props()).toMatchObject({
      title: ReportNotConfiguredInstance.i18n.title,
      svgPath: emptyStateSvgPath,
      primaryButtonText: ReportNotConfiguredInstance.i18n.primaryButtonText,
      primaryButtonLink: instanceDashboardSettingsPath,
      secondaryButtonText: ReportNotConfiguredInstance.i18n.secondaryButtonText,
      secondaryButtonLink: dashboardDocumentation,
      description: ReportNotConfiguredInstance.i18n.description,
    });
  });
});
