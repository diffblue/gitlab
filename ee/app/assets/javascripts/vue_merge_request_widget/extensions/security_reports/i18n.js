import { __, s__ } from '~/locale';

export const reportTypes = {
  SAST: s__('ciReport|SAST'),
  DAST: s__('ciReport|DAST'),
  DEPENDENCY_SCANNING: s__('ciReport|Dependency scanning'),
  CONTAINER_SCANNING: s__('ciReport|Container scanning'),
  SECRET_DETECTION: s__('ciReport|Secret detection'),
  COVERAGE_FUZZING: s__('ciReport|Coverage fuzzing'),
  API_FUZZING: s__('ciReport|API fuzzing'),
};

export const i18n = {
  new: __('New'),
  fixed: __('Fixed'),
  dismissed: __('Dismissed'),
  learnMore: __('Learn more'),
  label: s__('ciReport|Security scanning'),
  loading: s__('ciReport|Security scanning is loading'),
  loadingError: s__('ciReport|%{scanner}: Loading resulted in an error'),
  error: s__('ciReport|Security reports failed loading results'),
  fullReport: s__('ciReport|Full report'),
  helpPopoverTitle: s__('ciReport|Security scan results'),
  helpPopoverContent: s__(
    'ciReport|New vulnerabilities are vulnerabilities that the security scan detects in the merge request that are different to existing vulnerabilities in the default branch.',
  ),
  securityScanning: s__('ciReport|Security scanning'),
  highlights: s__(
    'ciReport|%{criticalStart}critical%{criticalEnd}, %{highStart}high%{highEnd} and %{otherStart}others%{otherEnd}',
  ),
  noNewVulnerabilities: s__('ciReport|%{scanner} detected no new potential vulnerabilities'),
  newVulnerabilities: s__('ciReport|%{scanner} detected %{number} new potential %{vulnStr}'),
  findingLoadingError: s__(
    'ciReport|Something went wrong while fetching the finding. Please try again later.',
  ),
};

export const popovers = {
  SAST_TEXT: s__('ciReport|Detects known vulnerabilities in your source code.'),
  SAST_TITLE: s__('ciReport|Static Application Security Testing (SAST)'),

  DAST_TEXT: s__('ciReport|Detects known vulnerabilities in your web application.'),
  DAST_TITLE: s__('ciReport|Dynamic Application Security Testing (DAST)'),

  CONTAINER_SCANNING_TITLE: reportTypes.CONTAINER_SCANNING,
  CONTAINER_SCANNING_TEXT: s__(
    'ciReport|Container scanning detects known vulnerabilities in your docker images.',
  ),

  DEPENDENCY_SCANNING_TITLE: reportTypes.DEPENDENCY_SCANNING,
  DEPENDENCY_SCANNING_TEXT: s__(
    "ciReport|Detects known vulnerabilities in your source code's dependencies.",
  ),

  SECRET_DETECTION_TITLE: reportTypes.SECRET_DETECTION,
  SECRET_DETECTION_TEXT: s__(
    'ciReport|Detects secrets and credentials vulnerabilities in your source code.',
  ),

  COVERAGE_FUZZING_TITLE: reportTypes.COVERAGE_FUZZING,
  API_FUZZING_TITLE: reportTypes.API_FUZZING,
};
