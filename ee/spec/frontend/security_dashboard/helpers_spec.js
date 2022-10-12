import {
  getFormattedSummary,
  preparePageInfo,
  getFormattedScanners,
} from 'ee/security_dashboard/helpers';

describe('getFormattedSummary', () => {
  it('returns a properly formatted array given a valid, non-empty summary', () => {
    const summary = {
      dast: { vulnerabilitiesCount: 0 },
      containerScanning: { vulnerabilitiesCount: 1 },
      dependencyScanning: { vulnerabilitiesCount: 2 },
    };

    expect(getFormattedSummary(summary)).toEqual([
      ['DAST', summary.dast],
      ['Container Scanning', summary.containerScanning],
      ['Dependency Scanning', summary.dependencyScanning],
    ]);
  });

  it('filters empty reports out', () => {
    const summary = {
      dast: { vulnerabilitiesCount: 0 },
      containerScanning: null,
      dependencyScanning: {},
    };

    expect(getFormattedSummary(summary)).toEqual([['DAST', summary.dast]]);
  });

  it('filters invalid report types out', () => {
    const summary = {
      dast: { vulnerabilitiesCount: 0 },
      invalidReportType: { vulnerabilitiesCount: 1 },
    };

    expect(getFormattedSummary(summary)).toEqual([['DAST', summary.dast]]);
  });

  it.each([undefined, [], [1], 'hello world', 123])(
    'returns an empty array when summary is %s',
    (summary) => {
      expect(getFormattedSummary(summary)).toEqual([]);
    },
  );
});

describe('preparePageInfo', () => {
  describe('when pageInfo is empty', () => {
    it('returns pageInfo object with hasNextPage set to false', () => {
      expect(preparePageInfo(null)).toEqual({ hasNextPage: false });
    });
  });

  describe('when pageInfo.endCursor is NULL', () => {
    it('returns pageInfo object with hasNextPage set to false', () => {
      expect(preparePageInfo({ endCursor: null })).toEqual({ endCursor: null, hasNextPage: false });
    });
  });

  describe('when pageInfo.endCursor is provided', () => {
    it('returns pageInfo object with hasNextPage set to true', () => {
      expect(preparePageInfo({ endCursor: 'ENDCURSORVALUE' })).toEqual({
        endCursor: 'ENDCURSORVALUE',
        hasNextPage: true,
      });
    });
  });
});

describe('getFormattedScanners', () => {
  const manuallyAddedScanner = {
    id: 'gid://gitlab/Vulnerabilities::Scanner/3',
    name: 'manually-created-vulnerability',
    reportType: 'GENERIC',
    vendor: 'GitLab',
  };
  const manuallyAddedName = 'Manually added';

  it('returns a formatted array', () => {
    const vulnerabilityScanners = [
      {
        id: 'gid://gitlab/Vulnerabilities::Scanner/1',
        name: 'Find Security Bugs',
        reportType: 'SAST',
        vendor: 'GitLab',
      },
      {
        id: 'gid://gitlab/Vulnerabilities::Scanner/2',
        name: 'ESLint',
        reportType: 'SAST',
        vendor: 'GitLab',
      },
      { ...manuallyAddedScanner },
    ];

    expect(getFormattedScanners(vulnerabilityScanners)).toEqual([
      {
        id: 'SAST',
        reportType: 'SAST',
        name: 'SAST',
        scannerIds: [
          'gid://gitlab/Vulnerabilities::Scanner/1',
          'gid://gitlab/Vulnerabilities::Scanner/2',
        ],
      },
      {
        id: 'GENERIC',
        reportType: 'GENERIC',
        name: manuallyAddedName,
        scannerIds: ['gid://gitlab/Vulnerabilities::Scanner/3'],
      },
    ]);
  });

  it('renames "GENERIC" report type to "Manually added"', () => {
    const vulnerabilityScanners = [{ ...manuallyAddedScanner }];

    expect(getFormattedScanners(vulnerabilityScanners)[0].name).toBe(manuallyAddedName);
  });

  it('sets the "GENERIC" report type as the default if no matching report type found', () => {
    const customReportTypeScanner = {
      ...manuallyAddedScanner,
      reportType: '',
    };
    const vulnerabilityScanners = [{ ...customReportTypeScanner }];

    expect(getFormattedScanners(vulnerabilityScanners)[0].name).toBe(manuallyAddedName);
  });

  it('sorts "GENERIC" as the last item and everything else alphabetically', () => {
    const unsortedVulnerabilityScanners = [
      { ...manuallyAddedScanner },
      { reportType: 'SAST' },
      { reportType: 'DEPENDENCY_SCANNING' },
      { reportType: 'CONTAINER_SCANNING' },
      { reportType: 'DAST' },
    ];

    const formattedReportTypes = getFormattedScanners(unsortedVulnerabilityScanners).map(
      ({ reportType }) => reportType,
    );

    expect(formattedReportTypes).toEqual([
      'CONTAINER_SCANNING',
      'DAST',
      'DEPENDENCY_SCANNING',
      'SAST',
      'GENERIC',
    ]);
  });
});
