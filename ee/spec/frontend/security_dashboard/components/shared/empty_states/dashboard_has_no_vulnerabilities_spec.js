import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import DashboardHasNoVulnerabilities from 'ee/security_dashboard/components/shared/empty_states/dashboard_has_no_vulnerabilities.vue';

describe('dashboard has no vulnerabilities empty state', () => {
  let wrapper;
  const emptyStateSvgPath = '/placeholder.svg';
  const dashboardDocumentation = '/path/to/dashboard/documentation';

  const createWrapper = () =>
    shallowMount(DashboardHasNoVulnerabilities, {
      provide: {
        emptyStateSvgPath,
        dashboardDocumentation,
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
      title: DashboardHasNoVulnerabilities.i18n.title,
      svgPath: emptyStateSvgPath,
      primaryButtonLink: dashboardDocumentation,
      primaryButtonText: DashboardHasNoVulnerabilities.i18n.primaryButtonText,
      description: DashboardHasNoVulnerabilities.i18n.description,
    });
  });
});
