/* eslint-disable import/export */
import { invert } from 'lodash';
import { s__ } from '~/locale';

import {
  reportTypeToSecurityReportTypeEnum as reportTypeToSecurityReportTypeEnumCE,
  REPORT_TYPE_API_FUZZING,
  REPORT_TYPE_BREACH_AND_ATTACK_SIMULATION,
  REPORT_TYPE_COVERAGE_FUZZING,
  REPORT_TYPE_DAST,
  REPORT_TYPE_DEPENDENCY_SCANNING,
  REPORT_TYPE_CONTAINER_SCANNING,
  REPORT_TYPE_CLUSTER_IMAGE_SCANNING,
} from '~/vue_shared/security_reports/constants';

export * from '~/vue_shared/security_reports/constants';

/**
 * SecurityReportTypeEnum values for use with GraphQL.
 *
 * These should correspond to the lowercase security scan report types.
 */
export const SECURITY_REPORT_TYPE_ENUM_API_FUZZING = 'API_FUZZING';
export const SECURITY_REPORT_TYPE_ENUM_BREACH_AND_ATTACK_SIMULATION =
  'BREACH_AND_ATTACK_SIMULATION';
export const SECURITY_REPORT_TYPE_ENUM_COVERAGE_FUZZING = 'COVERAGE_FUZZING';
export const SECURITY_REPORT_TYPE_ENUM_DAST = 'DAST';
export const SECURITY_REPORT_TYPE_ENUM_DEPENDENCY_SCANNING = 'DEPENDENCY_SCANNING';
export const SECURITY_REPORT_TYPE_ENUM_CONTAINER_SCANNING = 'CONTAINER_SCANNING';
export const SECURITY_REPORT_TYPE_ENUM_CLUSTER_IMAGE_SCANNING = 'CLUSTER_IMAGE_SCANNING';

/* Override CE Definitions */

/**
 * A mapping from security scan report types to SecurityReportTypeEnum values.
 */
export const reportTypeToSecurityReportTypeEnum = {
  ...reportTypeToSecurityReportTypeEnumCE,
  [REPORT_TYPE_API_FUZZING]: SECURITY_REPORT_TYPE_ENUM_API_FUZZING,
  [REPORT_TYPE_COVERAGE_FUZZING]: SECURITY_REPORT_TYPE_ENUM_COVERAGE_FUZZING,
  [REPORT_TYPE_BREACH_AND_ATTACK_SIMULATION]: SECURITY_REPORT_TYPE_ENUM_BREACH_AND_ATTACK_SIMULATION,
  [REPORT_TYPE_DAST]: SECURITY_REPORT_TYPE_ENUM_DAST,
  [REPORT_TYPE_DEPENDENCY_SCANNING]: SECURITY_REPORT_TYPE_ENUM_DEPENDENCY_SCANNING,
  [REPORT_TYPE_CONTAINER_SCANNING]: SECURITY_REPORT_TYPE_ENUM_CONTAINER_SCANNING,
  [REPORT_TYPE_CLUSTER_IMAGE_SCANNING]: SECURITY_REPORT_TYPE_ENUM_CLUSTER_IMAGE_SCANNING,
};

/**
 * A mapping from SecurityReportTypeEnum values to security scan report types.
 */
export const securityReportTypeEnumToReportType = invert(reportTypeToSecurityReportTypeEnum);

/**
 * Values for Security Scanner Info PopOvers including help Page Path Links
 */
export const sastPopover = {
  title: s__(
    'ciReport|Static Application Security Testing (SAST) detects potential vulnerabilities in your source code.',
  ),
  copy: s__('ciReport|%{linkStartTag}Learn more about SAST %{linkEndTag}'),
};

export const containerScanningPopover = {
  title: s__('ciReport|Container Scanning detects known vulnerabilities in your container images.'),
  copy: s__('ciReport|%{linkStartTag}Learn more about Container Scanning %{linkEndTag}'),
};

export const dastPopover = {
  title: s__(
    'ciReport|Dynamic Application Security Testing (DAST) detects vulnerabilities in your web application.',
  ),
  copy: s__('ciReport|%{linkStartTag}Learn more about DAST %{linkEndTag}'),
};

export const dependencyScanningPopover = {
  title: s__(
    "ciReport|Dependency Scanning detects known vulnerabilities in your project's dependencies.",
  ),
  copy: s__('ciReport|%{linkStartTag}Learn more about Dependency Scanning %{linkEndTag}'),
};

export const secretDetectionPopover = {
  title: s__('ciReport|Secret Detection detects leaked credentials in your source code.'),
  copy: s__('ciReport|%{linkStartTag}Learn more about Secret Detection %{linkEndTag}'),
};

export const coverageFuzzingPopover = {
  title: s__('ciReport|Coverage Fuzzing'),
  copy: s__('ciReport|%{linkStartTag}Learn more about Coverage Fuzzing %{linkEndTag}'),
};

export const apiFuzzingPopover = {
  title: s__('ciReport|API Fuzzing'),
  copy: s__('ciReport|%{linkStartTag}Learn more about API Fuzzing%{linkEndTag}'),
};
