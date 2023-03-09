import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import DashboardHasNoVulnerabilities from 'ee/security_dashboard/components/shared/empty_states/dashboard_has_no_vulnerabilities.vue';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

describe('dashboard has no vulnerabilities empty state', () => {
  let wrapper;
  const emptyStateSvgPath = '/placeholder.svg';

  const createWrapper = () =>
    shallowMount(DashboardHasNoVulnerabilities, {
      provide: {
        emptyStateSvgPath,
      },
    });

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('passes expected props to the GlEmptyState', () => {
    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: DashboardHasNoVulnerabilities.i18n.title,
      svgPath: emptyStateSvgPath,
      primaryButtonLink: DOC_PATH_SECURITY_CONFIGURATION,
      primaryButtonText: DashboardHasNoVulnerabilities.i18n.primaryButtonText,
      description: DashboardHasNoVulnerabilities.i18n.description,
    });
  });
});
