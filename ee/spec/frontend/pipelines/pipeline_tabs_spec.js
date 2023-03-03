import { createAppOptions } from 'ee/pipelines/pipeline_tabs';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import findingsQuery from 'ee/security_dashboard/graphql/queries/pipeline_findings.query.graphql';
import { dataset } from 'ee_jest/security_dashboard/mock_data/pipeline_report_dataset';
import { createAlert } from '~/alert';
import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { __ } from '~/locale';

const mockCeOptions = {
  foo: 'bar',
};

jest.mock('~/pipelines/pipeline_tabs', () => ({
  createAppOptions: () => mockCeOptions,
}));
jest.mock('~/alert');

describe('createAppOptions', () => {
  const EL_ID = 'EL_ID';

  let el;

  const createElement = () => {
    el = document.createElement('div');
    el.id = EL_ID;
    el.dataset.vulnerabilityReportData = JSON.stringify(dataset);

    document.body.appendChild(el);
  };

  afterEach(() => {
    el = null;
    document.body.innerHTML = '';
  });

  it('merges EE options with CE ones', () => {
    createElement();
    const options = createAppOptions(`#${EL_ID}`, null);

    expect(createAlert).not.toHaveBeenCalled();
    expect(options).toMatchObject({
      ...mockCeOptions,
      provide: {
        loadingErrorIllustrations: {
          [HTTP_STATUS_UNAUTHORIZED]: dataset.emptyStateUnauthorizedSvgPath,
          [HTTP_STATUS_FORBIDDEN]: dataset.emptyStateForbiddenSvgPath,
        },
        commitPathTemplate: dataset.commitPathTemplate,
        projectFullPath: dataset.projectFullPath,
        emptyStateSvgPath: dataset.emptyStateSvgPath,
        vulnerabilitiesEndpoint: dataset.vulnerabilitiesEndpoint,
        dashboardType: DASHBOARD_TYPES.PIPELINE,
        projectId: 123,
        fullPath: dataset.projectFullPath,
        canAdminVulnerability: true,
        pipeline: {
          id: 500,
          iid: 43,
          jobsPath: dataset.pipelineJobsPath,
          sourceBranch: dataset.sourceBranch,
        },
        canViewFalsePositive: true,
        vulnerabilitiesQuery: findingsQuery,
      },
    });
  });

  it('returns `null` if el does not exist', () => {
    expect(createAppOptions('foo', null)).toBe(null);
  });

  it('shows an error message if options cannot be parsed and just returns CE options', () => {
    createElement();
    delete el.dataset.vulnerabilityReportData;
    const options = createAppOptions(`#${EL_ID}`, null);

    expect(createAlert).toHaveBeenCalledWith({
      message: __("Unable to parse the vulnerability report's options."),
      error: expect.any(Error),
    });
    expect(options).toMatchObject(mockCeOptions);
  });
});
