export const licenses = [
  {
    name: 'Academic Free License v2.1',
    dependencies: [
      {
        name: 'json-schema',
        version: '0.4.0',
        package_manager: 'npm',
        blob_path: 'package.json',
      },
    ],
    url: 'http://opensource.linux-mirror.org/licenses/afl-2.1.txt',
    classification: {
      id: null,
      name: 'Academic Free License v2.1',
      approval_status: 'unclassified',
    },
    count: 1,
  },
  {
    name: 'Apache License 2.0',
    dependencies: [
      {
        name: 'websocket-driver',
        version: '0.7.4',
        package_manager: 'npm',
        blob_path: 'package.json',
      },
      {
        name: 'websocket-extensions',
        version: '0.1.4',
        package_manager: 'npm',
        blob_path: 'package.json',
      },
      {
        name: 'xml-name-validator',
        version: '3.0.0',
        package_manager: 'npm',
        blob_path: 'package.json',
      },
    ],
    url: 'https://opensource.org/licenses/Apache-2.0',
    classification: {
      id: null,
      name: 'Apache License 2.0',
      approval_status: 'denied',
    },
    count: 3,
  },
  {
    name: 'ISC License',
    dependencies: [
      {
        name: 'abbrev',
        version: '1.1.1',
        package_manager: 'npm',
        blob_path: 'package.json',
      },
      {
        name: 'anymatch',
        version: '2.0.0',
        package_manager: 'npm',
        blob_path: 'package.json',
      },
    ],
    url: 'https://opensource.org/licenses/ISC',
    classification: {
      id: 4,
      name: 'ISC License',
      approval_status: 'allowed',
    },
    count: 2,
  },
];

export const licenseComplianceSuccessExpanded = {
  new_licenses: licenses,
  existing_licenses: 0,
  removed_licenses: 0,
};

export const licenseComplianceNewLicenses = {
  new_licenses: 4,
  existing_licenses: 0,
  removed_licenses: 0,
};

export const licenseComplianceNewAndRemovedLicenses = {
  new_licenses: 2,
  existing_licenses: 0,
  removed_licenses: 1,
};

export const licenseComplianceNewDeniedLicenses = {
  new_licenses: 4,
  existing_licenses: 0,
  removed_licenses: 0,
  has_denied_licenses: true,
};

export const licenseComplianceNewDeniedLicensesAndExisting = {
  new_licenses: 4,
  existing_licenses: 2,
  removed_licenses: 0,
  has_denied_licenses: true,
};

export const licenseComplianceNewDeniedLicensesAndExistingApprovalRequired = {
  new_licenses: 4,
  existing_licenses: 2,
  removed_licenses: 1,
  has_denied_licenses: true,
  approval_required: true,
};

export const licenseComplianceNewAndRemovedLicensesApprovalRequired = {
  new_licenses: 4,
  existing_licenses: 0,
  removed_licenses: 1,
  has_denied_licenses: true,
  approval_required: true,
};

export const licenseComplianceRemovedLicenses = {
  new_licenses: 0,
  existing_licenses: 0,
  removed_licenses: 2,
};

export const licenseComplianceEmpty = {
  new_licenses: 0,
  existing_licenses: 0,
  removed_licenses: 0,
};

export const licenseComplianceEmptyExistingLicense = {
  new_licenses: 0,
  existing_licenses: 1,
  removed_licenses: 0,
};

export const licenseComplianceExistingAndNewLicenses = {
  new_licenses: 6,
  existing_licenses: 2,
  removed_licenses: 1,
  has_denied_licenses: false,
  approval_required: false,
};
