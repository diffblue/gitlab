import {
  getFormattedSummary,
  preparePageInfo,
  getFormattedScanners,
} from 'ee/security_dashboard/helpers';
import { REPORT_TYPES_WITH_MANUALLY_ADDED } from 'ee/security_dashboard/store/constants';

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
  const manuallyAddedAvailableScanner = {
    id: 'gid://gitlab/Vulnerabilities::Scanner/3',
    name: 'manually-created-vulnerability',
    reportType: 'GENERIC',
    vendor: 'GitLab',
  };
  const manuallyAddedName = 'Manually added';
  const allNotAvailableVulnerabilityScanners = [];

  it('returns all possible scanners', () => {
    expect(getFormattedScanners(allNotAvailableVulnerabilityScanners)).toHaveLength(
      Object.keys(REPORT_TYPES_WITH_MANUALLY_ADDED).length,
    );
  });

  it('returns empty scannerIds for not available scanners', () => {
    const unavailableScanners = getFormattedScanners(allNotAvailableVulnerabilityScanners);
    const unavailableScannerIds = unavailableScanners.map(({ scannerIds }) => scannerIds);

    unavailableScannerIds.forEach((value) => {
      expect(value).toEqual([]);
    });
  });

  it('sets disabled attribute for not available scanners', () => {
    const unavailableScanners = getFormattedScanners(allNotAvailableVulnerabilityScanners);
    const unavailableDisabledAttributes = unavailableScanners.map(({ disabled }) => disabled);

    unavailableDisabledAttributes.forEach((value) => {
      expect(value).toEqual(true);
    });
  });

  it('returns a formatted array for the available scanners', () => {
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
      { ...manuallyAddedAvailableScanner },
    ];

    expect(getFormattedScanners(vulnerabilityScanners)).toEqual(
      expect.arrayContaining([
        {
          id: 'SAST',
          reportType: 'SAST',
          name: 'SAST',
          scannerIds: [
            'gid://gitlab/Vulnerabilities::Scanner/1',
            'gid://gitlab/Vulnerabilities::Scanner/2',
          ],
          disabled: false,
        },
        {
          id: 'GENERIC',
          reportType: 'GENERIC',
          name: manuallyAddedName,
          scannerIds: ['gid://gitlab/Vulnerabilities::Scanner/3'],
          disabled: false,
        },
      ]),
    );
  });

  it('renames "GENERIC" report type to "Manually added"', () => {
    const vulnerabilityScanners = [{ ...manuallyAddedAvailableScanner }];
    const genericItemIndex = Object.keys(REPORT_TYPES_WITH_MANUALLY_ADDED).length - 1;

    expect(getFormattedScanners(vulnerabilityScanners)[genericItemIndex].name).toBe(
      manuallyAddedName,
    );
  });

  it('sets the "GENERIC" report type as the default if no matching report type found', () => {
    const customReportTypeScanner = {
      ...manuallyAddedAvailableScanner,
      reportType: '',
    };
    const vulnerabilityScanners = [{ ...customReportTypeScanner }];

    expect(getFormattedScanners(vulnerabilityScanners)[0].name).toBe(manuallyAddedName);
  });

  it('sorts "GENERIC" as the last item and everything else alphabetically', () => {
    const unsortedVulnerabilityScanners = [
      { ...manuallyAddedAvailableScanner },
      { reportType: 'SAST' },
      { reportType: 'DEPENDENCY_SCANNING' },
      { reportType: 'CONTAINER_SCANNING' },
      { reportType: 'DAST' },
    ];

    const formattedReportTypes = getFormattedScanners(unsortedVulnerabilityScanners).map(
      ({ reportType }) => reportType,
    );

    const allReportTypes = Object.keys(REPORT_TYPES_WITH_MANUALLY_ADDED).map((x) =>
      x.toUpperCase(),
    );

    expect(formattedReportTypes).toEqual(allReportTypes);
  });
});
