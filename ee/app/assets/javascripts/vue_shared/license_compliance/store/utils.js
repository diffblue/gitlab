import { groupBy } from 'lodash';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';
import { s__, n__, sprintf } from '~/locale';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/ci/reports/constants';

/**
 *
 * Converts the snake case in license objects to camel case
 *
 * @param license {Object} License Object
 * @returns {Object}
 *
 */
export const normalizeLicense = (license) => {
  const { approval_status: approvalStatus, ...rest } = license;
  return {
    ...rest,
    approvalStatus,
  };
};

export const getStatusTranslationsFromLicenseStatus = (approvalStatus) => {
  if (approvalStatus === LICENSE_APPROVAL_STATUS.ALLOWED) {
    return s__('LicenseCompliance|Allowed');
  } else if (approvalStatus === LICENSE_APPROVAL_STATUS.DENIED) {
    return s__('LicenseCompliance|Denied');
  }
  return '';
};

export const getIssueStatusFromLicenseStatus = (approvalStatus) => {
  if (approvalStatus === LICENSE_APPROVAL_STATUS.ALLOWED) {
    return STATUS_SUCCESS;
  } else if (approvalStatus === LICENSE_APPROVAL_STATUS.DENIED) {
    return STATUS_FAILED;
  }
  return STATUS_NEUTRAL;
};

export const getPackagesString = (packages, truncate, maxPackages) => {
  const translatedMessage = n__(
    'ciReport|Used by %{packagesString}',
    'ciReport|Used by %{packagesString}, and %{lastPackage}',
    packages.length,
  );

  let packagesString;
  let lastPackage = '';

  if (packages.length === 1) {
    // When there is only 1 package name to show.
    packagesString = packages[0].name;
  } else if (truncate && packages.length > maxPackages) {
    // When packages count is higher than displayPackageCount
    // and truncate is true.
    packagesString = packages
      .slice(0, maxPackages)
      .map((packageItem) => packageItem.name)
      .join(', ');
  } else {
    // Return all package names separated by comma with proper grammar
    packagesString = packages
      .slice(0, packages.length - 1)
      .map((packageItem) => packageItem.name)
      .join(', ');
    lastPackage = packages[packages.length - 1].name;
  }

  return sprintf(translatedMessage, {
    packagesString,
    lastPackage,
  });
};

/**
 * This converts the newer licence format into the old one so we can use it with our older components.
 *
 * NOTE: This helper is temporary and can be removed once we flip the `parsedLicenseReport` feature flag
 * The below issue is for tracking its removal:
 * https://gitlab.com/gitlab-org/gitlab/issues/33878
 *
 * @param {Object} license The license in the newer format that needs converting
 * @returns {Object} The converted license;
 */

export const convertToOldReportFormat = (license) => {
  const approvalStatus = license.classification.approval_status;

  return {
    ...license,
    approvalStatus,
    id: license.classification.id,
    packages: license.dependencies,
    status: getIssueStatusFromLicenseStatus(approvalStatus),
  };
};

/**
 * Takes an array of licenses and returns a function that takes an report-group objects
 *
 * It returns a fresh object, containing all properties of the original report-group and added "license" property,
 * containing an array of licenses, matching the report-group's status
 *
 * @param {Array} licenses
 * @returns {function(*): {licenses: (*|*[])}}
 */
export const addLicensesMatchingReportGroupStatus = (licenses) => {
  const licensesGroupedByStatus = groupBy(licenses, 'status');

  return (reportGroup) => ({
    ...reportGroup,
    licenses: licensesGroupedByStatus[reportGroup.status] || [],
  });
};

/**
 * Returns true of the given object has a "license" property, containing an array with at least licenses. Otherwise false.
 *
 *
 * @param {Object}
 * @returns {boolean}
 */
export const reportGroupHasAtLeastOneLicense = ({ licenses }) => licenses?.length > 0;
