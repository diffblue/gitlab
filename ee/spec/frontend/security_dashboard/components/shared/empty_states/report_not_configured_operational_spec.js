import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import ReportNotConfiguredOperational from 'ee/security_dashboard/components/shared/empty_states/report_not_configured_operational.vue';
import { DOC_PATH_POLICIES } from 'ee/security_dashboard/constants';

describe('Operational report not configured component', () => {
  let wrapper;
  const operationalConfigurationPath = '/operational-configuration';
  const operationalEmptyStateSvgPath = '/operational-placeholder.svg';

  const createComponent = ({ dashboardType = 'project' }) => {
    wrapper = shallowMount(ReportNotConfiguredOperational, {
      provide: {
        dashboardType,
        operationalConfigurationPath,
        operationalEmptyStateSvgPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    dashboardType | description                                                 | primaryButtonText
    ${'project'}  | ${ReportNotConfiguredOperational.i18n.description.project}  | ${ReportNotConfiguredOperational.i18n.primaryButtonText}
    ${'group'}    | ${ReportNotConfiguredOperational.i18n.description.group}    | ${''}
    ${'instance'} | ${ReportNotConfiguredOperational.i18n.description.instance} | ${''}
  `(
    'passes expected props to the GlEmptyState for the dashboardType report',
    ({ dashboardType, description, primaryButtonText }) => {
      createComponent({ dashboardType });

      expect(wrapper.find(GlEmptyState).props()).toMatchObject({
        title: ReportNotConfiguredOperational.i18n.title,
        svgPath: operationalEmptyStateSvgPath,
        primaryButtonText,
        primaryButtonLink: operationalConfigurationPath,
        secondaryButtonText: ReportNotConfiguredOperational.i18n.secondaryButtonText,
        secondaryButtonLink: DOC_PATH_POLICIES,
        description,
      });
    },
  );
});
