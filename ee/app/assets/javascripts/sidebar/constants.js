import { IssuableType } from '~/issues/constants';
import { __, s__, sprintf } from '~/locale';
import {
  IssuableAttributeType as IssuableAttributeTypeFoss,
  IssuableAttributeState as IssuableAttributeStateFoss,
  issuableAttributesQueries as issuableAttributesQueriesFoss,
  dropdowni18nText as dropdowni18nTextFoss,
  Tracking,
  defaultEpicSort,
  epicIidPattern,
} from '~/sidebar/constants';
import updateStatusMutation from '~/sidebar/queries/updateStatus.mutation.graphql';
import epicAncestorsQuery from './queries/epic_ancestors.query.graphql';
import groupEpicsQuery from './queries/group_epics.query.graphql';
import groupIterationsQuery from './queries/group_iterations.query.graphql';
import issueHealthStatusQuery from './queries/issue_health_status.query.graphql';
import issueWeightQuery from './queries/issue_weight.query.graphql';
import projectIssueEpicMutation from './queries/project_issue_epic.mutation.graphql';
import projectIssueEpicQuery from './queries/project_issue_epic.query.graphql';
import projectIssueIterationMutation from './queries/project_issue_iteration.mutation.graphql';
import projectIssueIterationQuery from './queries/project_issue_iteration.query.graphql';
import updateIssueWeightMutation from './queries/update_issue_weight.mutation.graphql';
import issueEscalationPolicyQuery from './queries/issue_escalation_policy.query.graphql';
import issueEscalationPolicyMutation from './queries/issue_escalation_policy.mutation.graphql';
import projectEscalationPoliciesQuery from './queries/project_escalation_policies.query.graphql';

export { Tracking, defaultEpicSort, epicIidPattern };

export const healthStatus = {
  ON_TRACK: 'onTrack',
  NEEDS_ATTENTION: 'needsAttention',
  AT_RISK: 'atRisk',
};

export const edit = __('Edit');
export const none = __('None');

export const healthStatusTextMap = {
  [healthStatus.ON_TRACK]: __('On track'),
  [healthStatus.NEEDS_ATTENTION]: __('Needs attention'),
  [healthStatus.AT_RISK]: __('At risk'),
};

export const iterationSelectTextMap = {
  iteration: __('Iteration'),
  noIteration: __('No iteration'),
  assignIteration: __('Assign Iteration'),
  iterationSelectFail: __('Failed to set iteration on this issue. Please try again.'),
  currentIterationFetchError: __('Failed to fetch the iteration for this issue. Please try again.'),
  iterationsFetchError: __('Failed to fetch the iterations for the group. Please try again.'),
  noIterationsFound: __('No iterations found'),
};

export const noIteration = null;
export const noAttributeId = null;

export const iterationDisplayState = 'opened';

export const healthStatusForRestApi = {
  NO_STATUS: '0',
  [healthStatus.ON_TRACK]: 'on_track',
  [healthStatus.NEEDS_ATTENTION]: 'needs_attention',
  [healthStatus.AT_RISK]: 'at_risk',
};

export const SIDEBAR_ESCALATION_POLICY_TITLE = __('Escalation policy');

export const MAX_DISPLAY_WEIGHT = 99999;

export const I18N_DROPDOWN = {
  dropdownHeaderText: s__('Sidebar|Assign health status'),
  noStatusText: s__('Sidebar|No status'),
  noneText: s__('Sidebar|None'),
  selectPlaceholderText: __('Select health status'),
};

export const CVE_ID_REQUEST_SIDEBAR_I18N = {
  action: s__('CVE|Request CVE ID'),
  description: s__('CVE|CVE ID Request'),
  createRequest: s__('CVE|Create CVE ID Request'),
  whyRequest: s__('CVE|Why Request a CVE ID?'),
  whyText1: s__(
    'CVE|Common Vulnerability Enumeration (CVE) identifiers are used to track distinct vulnerabilities in specific versions of code.',
  ),
  whyText2: s__(
    'CVE|As a maintainer, requesting a CVE for a vulnerability in your project will help your users stay secure and informed.',
  ),
  learnMore: __('Learn more'),
};

export const issuableIterationQueries = {
  [IssuableType.Issue]: {
    query: projectIssueIterationQuery,
    mutation: projectIssueIterationMutation,
  },
};

export const iterationsQueries = {
  [IssuableType.Issue]: {
    query: groupIterationsQuery,
  },
};

const issuableEpicQueries = {
  [IssuableType.Issue]: {
    query: projectIssueEpicQuery,
    mutation: projectIssueEpicMutation,
  },
};

const epicsQueries = {
  [IssuableType.Issue]: {
    query: groupEpicsQuery,
  },
};

const issuableEscalationPolicyQueries = {
  [IssuableType.Issue]: {
    query: issueEscalationPolicyQuery,
    mutation: issueEscalationPolicyMutation,
  },
};

const escalationPoliciesQueries = {
  [IssuableType.Issue]: {
    query: projectEscalationPoliciesQuery,
  },
};

export const IssuableAttributeType = {
  ...IssuableAttributeTypeFoss,
  Iteration: 'iteration',
  Epic: 'epic',
  EscalationPolicy: 'escalation policy', // eslint-disable-line @gitlab/require-i18n-strings
};

export const IssuableAttributeState = {
  ...IssuableAttributeStateFoss,
  [IssuableAttributeType.Iteration]: 'opened',
  [IssuableAttributeType.Epic]: 'opened',
};

export const issuableAttributesQueries = {
  ...issuableAttributesQueriesFoss,
  [IssuableAttributeType.Iteration]: {
    current: issuableIterationQueries,
    list: iterationsQueries,
  },
  [IssuableAttributeType.Epic]: {
    current: issuableEpicQueries,
    list: epicsQueries,
  },
  [IssuableAttributeType.EscalationPolicy]: {
    current: issuableEscalationPolicyQueries,
    list: escalationPoliciesQueries,
  },
};

export const ancestorsQueries = {
  [IssuableType.Epic]: {
    query: epicAncestorsQuery,
  },
};

export const weightQueries = {
  [IssuableType.Issue]: {
    query: issueWeightQuery,
    mutation: updateIssueWeightMutation,
  },
};

export const healthStatusQueries = {
  [IssuableType.Issue]: {
    mutation: updateStatusMutation,
    query: issueHealthStatusQuery,
  },
  [IssuableType.Epic]: {
    mutation: updateStatusMutation,
    query: issueHealthStatusQuery,
  },
};

export function dropdowni18nText(issuableAttribute, issuableType) {
  let noAttributesFound = s__('DropdownWidget|No %{issuableAttribute} found');

  if (issuableAttribute === IssuableAttributeType.Iteration) {
    noAttributesFound = s__('DropdownWidget|No open %{issuableAttribute} found');
  }

  return {
    ...dropdowni18nTextFoss(issuableAttribute, issuableType),
    noAttributesFound: sprintf(noAttributesFound, {
      issuableAttribute,
    }),
  };
}
