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
      approval_status: 'blacklisted',
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
      approval_status: 'approved',
    },
    count: 2,
  },
];

export const licenseComplianceSuccess = {
  new_licenses: licenses,
  existing_licenses: [],
  removed_licenses: [],
};

export const licenseComplianceNewAndRemovedLicenses = {
  new_licenses: licenses,
  existing_licenses: [],
  removed_licenses: licenses,
};

export const licenseComplianceRemovedLicenses = {
  new_licenses: [],
  existing_licenses: [],
  removed_licenses: licenses,
};

export const licenseComplianceEmpty = {
  new_licenses: [],
  existing_licenses: [],
  removed_licenses: [],
};
