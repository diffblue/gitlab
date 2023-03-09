import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import ReportNotConfiguredInstance from 'ee/security_dashboard/components/instance/report_not_configured_instance.vue';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

describe('Instance report not configured component', () => {
  let wrapper;
  const instanceDashboardSettingsPath = '/path/to/dashboard/settings';
  const emptyStateSvgPath = '/placeholder.svg';

  const createWrapper = () =>
    shallowMount(ReportNotConfiguredInstance, {
      provide: {
        emptyStateSvgPath,
        instanceDashboardSettingsPath,
      },
    });

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('passes expected props to the GlEmptyState', () => {
    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: ReportNotConfiguredInstance.i18n.title,
      svgPath: emptyStateSvgPath,
      primaryButtonText: ReportNotConfiguredInstance.i18n.primaryButtonText,
      primaryButtonLink: instanceDashboardSettingsPath,
      secondaryButtonText: ReportNotConfiguredInstance.i18n.secondaryButtonText,
      secondaryButtonLink: DOC_PATH_SECURITY_CONFIGURATION,
      description: ReportNotConfiguredInstance.i18n.description,
    });
  });
});
