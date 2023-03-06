import { __, s__ } from '~/locale';
import vulnerabilityStateMutations from 'ee/security_dashboard/graphql/mutate_vulnerability_state';
import {
  FEEDBACK_TYPE_ISSUE,
  FEEDBACK_TYPE_MERGE_REQUEST,
} from '~/vue_shared/security_reports/constants';

const falsePositiveMessage = s__('VulnerabilityManagement|Will not fix or a false-positive');

export const DISMISSAL_REASONS = {
  acceptable_risk: s__('VulnerabilityDismissalReasons|Acceptable risk'),
  false_positive: s__('VulnerabilityDismissalReasons|False positive'),
  mitigating_control: s__('VulnerabilityDismissalReasons|Mitigating control'),
  used_in_tests: s__('VulnerabilityDismissalReasons|Used in tests'),
  not_applicable: s__('VulnerabilityDismissalReasons|Not applicable'),
};

export const VULNERABILITY_STATES = {
  detected: s__('VulnerabilityStatusTypes|Needs triage'),
  confirmed: s__('VulnerabilityStatusTypes|Confirmed'),
  dismissed: s__('VulnerabilityStatusTypes|Dismissed'),
  resolved: s__('VulnerabilityStatusTypes|Resolved'),
};

export const VULNERABILITY_STATE_OBJECTS = {
  detected: {
    action: 'revert',
    state: 'detected',
    buttonText: VULNERABILITY_STATES.detected,
    dropdownText: s__('VulnerabilityManagement|Needs triage'),
    dropdownDescription: s__('VulnerabilityManagement|Requires assessment'),
    description: s__('VulnerabilityManagement|An unverified non-confirmed finding'),
    mutation: vulnerabilityStateMutations.revert,
  },
  confirmed: {
    action: 'confirm',
    state: 'confirmed',
    buttonText: VULNERABILITY_STATES.confirmed,
    dropdownText: __('Confirm'),
    dropdownDescription: s__('VulnerabilityManagement|A true-positive and will fix'),
    description: s__('VulnerabilityManagement|A verified true-positive vulnerability'),
    mutation: vulnerabilityStateMutations.confirm,
  },
  dismissed: {
    action: 'dismiss',
    state: 'dismissed',
    buttonText: VULNERABILITY_STATES.dismissed,
    dropdownText: __('Dismiss'),
    dropdownDescription: falsePositiveMessage,
    mutation: vulnerabilityStateMutations.dismiss,
    payload: {
      comment: falsePositiveMessage,
    },
  },
  resolved: {
    action: 'resolve',
    state: 'resolved',
    buttonText: VULNERABILITY_STATES.resolved,
    dropdownText: __('Resolve'),
    dropdownDescription: s__('VulnerabilityManagement|Verified as fixed or mitigated'),
    description: s__('VulnerabilityManagement|A removed or remediated vulnerability'),
    mutation: vulnerabilityStateMutations.resolve,
  },
};

export const HEADER_ACTION_BUTTONS = {
  mergeRequestCreation: {
    name: s__('ciReport|Resolve with merge request'),
    tagline: s__('ciReport|Automatically apply the patch in a new branch'),
    action: 'createMergeRequest',
  },
  patchDownload: {
    name: s__('ciReport|Download patch to resolve'),
    tagline: s__('ciReport|Download the patch to apply it manually'),
    action: 'downloadPatch',
  },
};

export const FEEDBACK_TYPES = {
  ISSUE: FEEDBACK_TYPE_ISSUE,
  MERGE_REQUEST: FEEDBACK_TYPE_MERGE_REQUEST,
};

export const RELATED_ISSUES_ERRORS = {
  LINK_ERROR: s__('VulnerabilityManagement|Could not process %{issueReference}: %{errorMessage}.'),
  UNLINK_ERROR: s__(
    'VulnerabilityManagement|Something went wrong while trying to unlink the issue. Please try again later.',
  ),
  ISSUE_ID_ERROR: s__('VulnerabilityManagement|invalid issue link or ID'),
};

export const REGEXES = {
  ISSUE_FORMAT: /^#?(\d+)$/, // Matches '123' and '#123'.
  LINK_FORMAT: /\/(.+\/.+)\/-\/issues\/(\d+)/, // Matches '/username/project/-/issues/123'.
};

export const SUPPORTING_MESSAGE_TYPES = {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  RECORDED: 'Recorded',
};

export const SUPPORTED_IDENTIFIER_TYPE_CWE = 'cwe';
export const SUPPORTED_IDENTIFIER_TYPE_OWASP = 'owasp';

export const VULNERABILITY_TRAINING_HEADING = {
  title: s__('Vulnerability|Training'),
};

export const SECURITY_TRAINING_URL_STATUS_COMPLETED = 'COMPLETED';
export const SECURITY_TRAINING_URL_STATUS_PENDING = 'PENDING';
