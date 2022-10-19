import isPlainObject from 'lodash/isPlainObject';
import groupBy from 'lodash/groupBy';
import {
  REPORT_TYPES_WITH_MANUALLY_ADDED,
  REPORT_TYPES_WITH_CLUSTER_IMAGE,
  REPORT_TYPES_ALL,
  SEVERITY_LEVELS,
} from 'ee/security_dashboard/store/constants';
import convertReportType from 'ee/vue_shared/security_reports/store/utils/convert_report_type';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import { SCANNER_NAMES_MAP } from '~/security_configuration/components/constants';
import { DEFAULT_SCANNER } from './constants';

const parseOptions = (obj) =>
  Object.entries(obj).map(([id, name]) => ({ id: id.toUpperCase(), name }));

const toolName = s__('SecurityReports|Tool');
const allToolsName = s__('ciReport|All tools');
const stateOptions = parseOptions(VULNERABILITY_STATES);
const defaultStateOptions = stateOptions.filter((x) => ['DETECTED', 'CONFIRMED'].includes(x.id));

export const stateFilter = {
  name: s__('SecurityReports|Status'),
  id: 'state',
  options: stateOptions,
  allOption: { id: 'all', name: s__('VulnerabilityStatusTypes|All statuses') },
  defaultOptions: defaultStateOptions,
};

export const severityFilter = {
  name: s__('SecurityReports|Severity'),
  id: 'severity',
  options: parseOptions(SEVERITY_LEVELS),
  allOption: { name: s__('ciReport|All severities') },
  defaultOptions: [],
};

export const createScannerOption = (vendor, reportType) => {
  const type = reportType.toUpperCase();

  return {
    id: `${vendor}.${type}`,
    reportType: reportType.toUpperCase(),
    name: convertReportType(reportType),
    scannerIds: [],
  };
};

// This is used on the pipeline security tab, group-level report, and instance-level report. It's
// used by the scanner filter that shows a flat list of scan types (DAST, SAST, etc) with no vendor
// grouping.
export const simpleScannerFilter = {
  name: toolName,
  id: 'reportType',
  options: parseOptions(REPORT_TYPES_WITH_MANUALLY_ADDED),
  allOption: { name: allToolsName },
  defaultOptions: [],
};

export const simpleScannerFilterPipeline = {
  name: toolName,
  id: 'reportType',
  options: parseOptions(REPORT_TYPES_WITH_CLUSTER_IMAGE),
  allOption: { name: allToolsName },
  defaultOptions: [],
};

// This is used on the project-level report. It's used by the scanner filter that shows a list of
// scan types (DAST, SAST, etc) that's grouped by vendor.
export const vendorScannerFilter = {
  name: toolName,
  id: 'scanner',
  options: Object.keys(REPORT_TYPES_WITH_MANUALLY_ADDED).map((x) =>
    createScannerOption(DEFAULT_SCANNER, x),
  ),
  allOption: { name: allToolsName },
  defaultOptions: [],
};

export const activityOptions = {
  NO_ACTIVITY: { id: 'NO_ACTIVITY', name: s__('SecurityReports|No activity') },
  WITH_ISSUES: { id: 'WITH_ISSUES', name: s__('SecurityReports|With issues') },
  NO_LONGER_DETECTED: { id: 'NO_LONGER_DETECTED', name: s__('SecurityReports|No longer detected') },
};

export const activityFilter = {
  name: s__('Reports|Activity'),
  id: 'activity',
  options: Object.values(activityOptions),
  allOption: { name: s__('SecurityReports|All activity') },
  defaultOptions: [],
};

export const projectFilter = {
  name: s__('SecurityReports|Project'),
  id: 'projectId',
  options: [],
  allOption: { name: s__('ciReport|All projects') },
  defaultOptions: [],
};

export const clusterFilter = {
  name: s__('SecurityReports|Cluster'),
  id: 'cluster',
  options: [],
  allOption: { name: s__('ciReport|All clusters') },
  defaultOptions: [],
};

export const imageFilter = {
  name: s__('SecurityReports|Image'),
  id: 'image',
  options: [],
  allOption: { name: s__('ciReport|All images') },
  defaultOptions: [],
};

/**
 * Provided a security reports summary from the GraphQL API, this returns an array of arrays
 * representing a properly formatted report ready to be displayed in the UI. Each sub-array consists
 * of the user-friend report's name, and the summary's payload. Note that summary entries are
 * considered empty and are filtered out of the return if the payload is `null` or don't include
 * a vulnerabilitiesCount property. Report types whose name can't be matched to a user-friendly
 * name are filtered out as well.
 *
 * Take the following summary for example:
 * {
 *   containerScanning: { vulnerabilitiesCount: 123 },
 *   invalidReportType: { vulnerabilitiesCount: 123 },
 *   dast: null,
 * }
 *
 * The formatted summary would look like this:
 * [
 *   ['containerScanning', { vulnerabilitiesCount: 123 }]
 * ]
 *
 * Note that `invalidReportType` was filtered out as it can't be matched with a user-friendly name,
 * and the DAST report was omitted because it's empty (`null`).
 *
 * @param {Object} rawSummary
 * @returns {Array}
 */
export const getFormattedSummary = (rawSummary = {}) => {
  if (!isPlainObject(rawSummary)) {
    return [];
  }
  // Convert keys to snake case so they can be matched against REPORT_TYPES keys for translation
  const snakeCasedSummary = convertObjectPropsToSnakeCase(rawSummary);
  // Convert object to an array of entries to make it easier to loop through
  const summaryEntries = Object.entries(snakeCasedSummary);
  // Filter out empty entries as we don't want to display those in the summary
  const withoutEmptyEntries = summaryEntries.filter(
    ([, scanSummary]) => scanSummary?.vulnerabilitiesCount !== undefined,
  );
  // Replace keys with translations found in REPORT_TYPES if available
  const formattedEntries = withoutEmptyEntries.map(([scanType, scanSummary]) => {
    const name = REPORT_TYPES_ALL[scanType];
    return name ? [name, scanSummary] : null;
  });
  // Filter out keys that could not be matched with any translation and are thus considered invalid
  return formattedEntries.filter((entry) => entry !== null);
};

/**
 * We have disabled loading hasNextPage from GraphQL as it causes timeouts in database,
 * instead we have to calculate that value based on the existence of endCursor. When endCursor
 * is empty or has null value, that means that there is no next page to be loaded from GraphQL API.
 *
 * @param {Object} pageInfo
 * @returns {Object}
 */
export const preparePageInfo = (pageInfo) => {
  return { ...pageInfo, hasNextPage: Boolean(pageInfo?.endCursor) };
};

/**
 * Provided a groupBy vulnerability scanners, this returns an array that is
 * sorted alphabetically with the "GENERIC" custom scanner name as the last item
 *
 * @param {Object} groupedByReportType
 * @returns {Array} sorted groupedByReportType
 */
const sortGroupedReportType = (groupedByReportType) => {
  const manuallyAddedScannerId = 'GENERIC';

  return Object.entries(groupedByReportType).sort(([a], [b]) => {
    if (a === manuallyAddedScannerId) return 1;
    if (b === manuallyAddedScannerId) return -1;

    return a.localeCompare(b);
  });
};

/**
 * Provided a vulnerability scanners from the GraphQL API, this returns an array that is
 * formatted so it can be displayed in the dropdown UI.
 *
 * @param {Array} vulnerabilityScanners
 * @returns {Array} formatted vulnerabilityScanners
 */
export const getFormattedScanners = (vulnerabilityScanners) => {
  const groupedByReportType = groupBy(vulnerabilityScanners, 'reportType');
  const sortedGroupedByReportType = sortGroupedReportType(groupedByReportType);

  return sortedGroupedByReportType.map(([reportType, scanners]) => {
    return {
      id: reportType,
      reportType,
      name: SCANNER_NAMES_MAP[reportType] || SCANNER_NAMES_MAP.GENERIC,
      scannerIds: scanners.map(({ id }) => id),
    };
  });
};

export const PROJECT_LOADING_ERROR_MESSAGE = __('An error occurred while retrieving projects.');

export default () => ({});
