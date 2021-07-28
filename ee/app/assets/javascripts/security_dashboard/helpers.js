import isPlainObject from 'lodash/isPlainObject';
import { REPORT_TYPES, SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import { BASE_FILTERS } from 'ee/security_dashboard/store/modules/filters/constants';
import convertReportType from 'ee/vue_shared/security_reports/store/utils/convert_report_type';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import { DEFAULT_SCANNER } from './constants';

const parseOptions = (obj) =>
  Object.entries(obj).map(([id, name]) => ({ id: id.toUpperCase(), name }));

export const mapProjects = (projects = []) =>
  projects.map((p) => ({ id: getIdFromGraphQLId(p.id).toString(), name: p.name }));

const stateOptions = parseOptions(VULNERABILITY_STATES);
const defaultStateOptions = stateOptions.filter((x) => ['DETECTED', 'CONFIRMED'].includes(x.id));

export const stateFilter = {
  name: s__('SecurityReports|Status'),
  id: 'state',
  options: stateOptions,
  allOption: BASE_FILTERS.state,
  defaultOptions: defaultStateOptions,
};

export const severityFilter = {
  name: s__('SecurityReports|Severity'),
  id: 'severity',
  options: parseOptions(SEVERITY_LEVELS),
  allOption: BASE_FILTERS.severity,
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
  name: s__('SecurityReports|Scanner'),
  id: 'reportType',
  options: parseOptions(REPORT_TYPES),
  allOption: BASE_FILTERS.report_type,
  defaultOptions: [],
};

// This is used on the project-level report. It's used by the scanner filter that shows a list of
// scan types (DAST, SAST, etc) that's grouped by vendor.
export const vendorScannerFilter = {
  name: s__('SecurityReports|Scanner'),
  id: 'scanner',
  options: Object.keys(REPORT_TYPES).map((x) => createScannerOption(DEFAULT_SCANNER, x)),
  allOption: BASE_FILTERS.report_type,
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
  allOption: BASE_FILTERS.activity,
  defaultOptions: [],
};

export const getProjectFilter = (projects) => {
  return {
    name: s__('SecurityReports|Project'),
    id: 'projectId',
    options: mapProjects(projects),
    allOption: BASE_FILTERS.project_id,
    defaultOptions: [],
  };
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
    const name = REPORT_TYPES[scanType];
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

export const PROJECT_LOADING_ERROR_MESSAGE = __('An error occurred while retrieving projects.');

export default () => ({});
