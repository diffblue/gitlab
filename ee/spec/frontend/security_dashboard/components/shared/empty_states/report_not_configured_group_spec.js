import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import ReportNotConfiguredGroup from 'ee/security_dashboard/components/group/report_not_configured_group.vue';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

describe('Group report not configured component', () => {
  let wrapper;
  const emptyStateSvgPath = '/placeholder.svg';

  const createWrapper = () =>
    shallowMount(ReportNotConfiguredGroup, {
      provide: {
        emptyStateSvgPath,
      },
    });

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('passes expected props to the GlEmptyState', () => {
    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: ReportNotConfiguredGroup.i18n.title,
      svgPath: emptyStateSvgPath,
      secondaryButtonText: ReportNotConfiguredGroup.i18n.secondaryButtonText,
      secondaryButtonLink: DOC_PATH_SECURITY_CONFIGURATION,
      description: ReportNotConfiguredGroup.i18n.description,
    });
  });
});
