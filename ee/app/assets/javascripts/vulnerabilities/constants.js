import { s__ } from '~/locale';
import {
  FEEDBACK_TYPE_ISSUE,
  FEEDBACK_TYPE_MERGE_REQUEST,
} from '~/vue_shared/security_reports/constants';

const falsePositiveMessage = s__('VulnerabilityManagement|Will not fix or a false-positive');

export const VULNERABILITY_STATE_OBJECTS = {
  detected: {
    action: 'revert',
    state: 'detected',
    statusBoxStyle: 'expired',
    displayName: s__('VulnerabilityManagement|Detected'),
    description: s__('VulnerabilityManagement|Needs triage'),
  },
  dismissed: {
    action: 'dismiss',
    state: 'dismissed',
    displayName: s__('Dismiss'),
    description: falsePositiveMessage,
    payload: {
      comment: falsePositiveMessage,
    },
  },
  confirmed: {
    action: 'confirm',
    state: 'confirmed',
    displayName: s__('Confirm'),
    description: s__('VulnerabilityManagement|A true-positive and will fix'),
  },
  resolved: {
    action: 'resolve',
    state: 'resolved',
    displayName: s__('Resolve'),
    description: s__('VulnerabilityManagement|Verified as fixed or mitigated'),
  },
};

export const VULNERABILITY_STATES = {
  detected: s__('VulnerabilityStatusTypes|Detected'),
  confirmed: s__('VulnerabilityStatusTypes|Confirmed'),
  dismissed: s__('VulnerabilityStatusTypes|Dismissed'),
  resolved: s__('VulnerabilityStatusTypes|Resolved'),
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
