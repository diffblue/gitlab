/* eslint-disable import/export */
import { invert } from 'lodash';
import {
  reportTypeToSecurityReportTypeEnum as reportTypeToSecurityReportTypeEnumCE,
  REPORT_TYPE_API_FUZZING,
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
  [REPORT_TYPE_DAST]: SECURITY_REPORT_TYPE_ENUM_DAST,
  [REPORT_TYPE_DEPENDENCY_SCANNING]: SECURITY_REPORT_TYPE_ENUM_DEPENDENCY_SCANNING,
  [REPORT_TYPE_CONTAINER_SCANNING]: SECURITY_REPORT_TYPE_ENUM_CONTAINER_SCANNING,
  [REPORT_TYPE_CLUSTER_IMAGE_SCANNING]: SECURITY_REPORT_TYPE_ENUM_CLUSTER_IMAGE_SCANNING,
};

/**
 * A mapping from SecurityReportTypeEnum values to security scan report types.
 */
export const securityReportTypeEnumToReportType = invert(reportTypeToSecurityReportTypeEnum);
