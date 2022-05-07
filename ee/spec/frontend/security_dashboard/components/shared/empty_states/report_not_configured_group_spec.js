import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import ReportNotConfiguredGroup from 'ee/security_dashboard/components/group/report_not_configured_group.vue';

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

  it('passes expected props to the GlEmptyState', () => {
    expect(wrapper.find(GlEmptyState).props()).toMatchObject({
      title: ReportNotConfiguredGroup.i18n.title,
      svgPath: emptyStateSvgPath,
      secondaryButtonText: ReportNotConfiguredGroup.i18n.secondaryButtonText,
      secondaryButtonLink: dashboardDocumentation,
      description: ReportNotConfiguredGroup.i18n.description,
    });
  });
});
