import { s__, sprintf } from '~/locale';
import {
  TRANSLATION_IS_LOADING,
  TRANSLATION_HAS_ERROR,
} from '~/vue_shared/security_reports/store/messages';

const SAST = s__('ciReport|SAST');
const DAST = s__('ciReport|DAST');
const CONTAINER_SCANNING = s__('ciReport|Container scanning');
const DEPENDENCY_SCANNING = s__('ciReport|Dependency scanning');
const SECRET_DETECTION = s__('ciReport|Secret detection');
const COVERAGE_FUZZING = s__('ciReport|Coverage fuzzing');
const API_FUZZING = s__('ciReport|API fuzzing');

export default {
  SAST,
  DAST,
  CONTAINER_SCANNING,
  DEPENDENCY_SCANNING,
  SECRET_DETECTION,
  COVERAGE_FUZZING,
  API_FUZZING,
  TRANSLATION_IS_LOADING,
  TRANSLATION_HAS_ERROR,
  SAST_IS_LOADING: sprintf(TRANSLATION_IS_LOADING, { reportType: SAST }),
  SAST_HAS_ERROR: sprintf(TRANSLATION_HAS_ERROR, { reportType: SAST }),
  DAST_IS_LOADING: sprintf(TRANSLATION_IS_LOADING, { reportType: DAST }),
  DAST_HAS_ERROR: sprintf(TRANSLATION_HAS_ERROR, { reportType: DAST }),
  CONTAINER_SCANNING_IS_LOADING: sprintf(TRANSLATION_IS_LOADING, {
    reportType: CONTAINER_SCANNING,
  }),
  CONTAINER_SCANNING_HAS_ERROR: sprintf(TRANSLATION_HAS_ERROR, { reportType: CONTAINER_SCANNING }),
  DEPENDENCY_SCANNING_IS_LOADING: sprintf(TRANSLATION_IS_LOADING, {
    reportType: DEPENDENCY_SCANNING,
  }),
  DEPENDENCY_SCANNING_HAS_ERROR: sprintf(TRANSLATION_HAS_ERROR, {
    reportType: DEPENDENCY_SCANNING,
  }),
  SECRET_DETECTION_IS_LOADING: sprintf(TRANSLATION_IS_LOADING, {
    reportType: SECRET_DETECTION,
  }),
  SECRET_DETECTION_HAS_ERROR: sprintf(TRANSLATION_HAS_ERROR, { reportType: SECRET_DETECTION }),
  COVERAGE_FUZZING_IS_LOADING: sprintf(TRANSLATION_IS_LOADING, {
    reportType: COVERAGE_FUZZING,
  }),
  COVERAGE_FUZZING_HAS_ERROR: sprintf(TRANSLATION_HAS_ERROR, { reportType: COVERAGE_FUZZING }),
  API_FUZZING_IS_LOADING: sprintf(TRANSLATION_IS_LOADING, {
    reportType: API_FUZZING,
  }),
  API_FUZZING_HAS_ERROR: sprintf(TRANSLATION_HAS_ERROR, { reportType: API_FUZZING }),
};
