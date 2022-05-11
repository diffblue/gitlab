import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import ReportNotConfiguredOperational from 'ee/security_dashboard/components/shared/empty_states/report_not_configured_operational.vue';

describe('Operational report not configured component', () => {
  let wrapper;
  const operationalConfigurationPath = '/operational-configuration';
  const operationalEmptyStateSvgPath = '/operational-placeholder.svg';
  const operationalHelpPath = '/operational-help';

  const createComponent = ({ dashboardType = 'project' }) => {
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
        secondaryButtonLink: operationalHelpPath,
        description,
      });
    },
  );
});
