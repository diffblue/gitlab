import { invert } from 'lodash';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { __, s__, sprintf } from '~/locale';
import {
  IssuableAttributeType as IssuableAttributeTypeFoss,
  IssuableAttributeState as IssuableAttributeStateFoss,
  LocalizedIssuableAttributeType as LocalizedIssuableAttributeTypeFoss,
  issuableAttributesQueries as issuableAttributesQueriesFoss,
  dropdowni18nText as dropdowni18nTextFoss,
  Tracking,
  defaultEpicSort,
  epicIidPattern,
} from '~/sidebar/constants';
import updateStatusMutation from '~/sidebar/queries/update_status.mutation.graphql';
import issuableWeightSubscription from '../graphql_shared/subscriptions/issuable_weight.subscription.graphql';
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
import issuableEpicSubscription from './queries/issuable_epic.subscription.graphql';

export { Tracking, defaultEpicSort, epicIidPattern };

export const edit = __('Edit');
export const none = __('None');

export const HEALTH_STATUS_I18N_ASSIGN_HEALTH_STATUS = s__('Sidebar|Assign health status');
export const HEALTH_STATUS_I18N_FETCH_ERROR = __(
  'An error occurred while fetching the health status.',
);
export const HEALTH_STATUS_I18N_HEALTH_STATUS = s__('Sidebar|Health status');
export const HEALTH_STATUS_I18N_NO_STATUS = s__('Sidebar|No status');
export const HEALTH_STATUS_I18N_NONE = s__('Sidebar|None');
export const HEALTH_STATUS_I18N_SELECT_HEALTH_STATUS = __('Select health status');
export const HEALTH_STATUS_I18N_UPDATE_ERROR = __(
  'Something went wrong while setting %{issuableType} health status.',
);
export const HEALTH_STATUS_OPEN_DROPDOWN_DELAY = 100;

export const HEALTH_STATUS_AT_RISK = 'atRisk';
export const HEALTH_STATUS_NEEDS_ATTENTION = 'needsAttention';
export const HEALTH_STATUS_ON_TRACK = 'onTrack';

export const healthStatusTextMap = {
  [HEALTH_STATUS_ON_TRACK]: __('On track'),
  [HEALTH_STATUS_NEEDS_ATTENTION]: __('Needs attention'),
  [HEALTH_STATUS_AT_RISK]: __('At risk'),
};

export const healthStatusForRestApi = {
  NO_STATUS: '0',
  [HEALTH_STATUS_ON_TRACK]: 'on_track',
  [HEALTH_STATUS_NEEDS_ATTENTION]: 'needs_attention',
  [HEALTH_STATUS_AT_RISK]: 'at_risk',
};

export const healthStatusDropdownOptions = [
  { text: __('On track'), value: HEALTH_STATUS_ON_TRACK },
  { text: __('Needs attention'), value: HEALTH_STATUS_NEEDS_ATTENTION },
  { text: __('At risk'), value: HEALTH_STATUS_AT_RISK },
];

export const healthStatusTracking = {
  event: Tracking.editEvent,
  label: Tracking.rightSidebarLabel,
  property: 'health_status',
};

export const iterationSelectTextMap = {
  iteration: __('Iteration'),
  noIteration: __('No iteration'),
  assignIteration: __('Assign Iteration'),
  iterationSelectFail: __('Failed to set iteration on this issue. Please try again.'),
  currentIterationFetchError: __('Failed to fetch the iteration for this issue. Please try again.'),
  iterationsFetchError: __('Failed to fetch the iterations for the group. Please try again.'),
  noIterationsFound: s__('Iterations|No iterations found'),
};

export const noAttributeId = null;

export const noEpic = {
  id: 0,
  title: __('No Epic'),
};

export const placeholderEpic = {
  id: -1,
  title: __('Select epic'),
};

export const SIDEBAR_ESCALATION_POLICY_TITLE = __('Escalation policy');

export const MAX_DISPLAY_WEIGHT = 99999;

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
  [TYPE_ISSUE]: {
    query: projectIssueIterationQuery,
    mutation: projectIssueIterationMutation,
  },
};

export const iterationsQueries = {
  [TYPE_ISSUE]: {
    query: groupIterationsQuery,
  },
};

const issuableEpicQueries = {
  [TYPE_ISSUE]: {
    query: projectIssueEpicQuery,
    mutation: projectIssueEpicMutation,
  },
};

const epicsQueries = {
  [TYPE_ISSUE]: {
    query: groupEpicsQuery,
  },
};

const issuableEscalationPolicyQueries = {
  [TYPE_ISSUE]: {
    query: issueEscalationPolicyQuery,
    mutation: issueEscalationPolicyMutation,
  },
};

const escalationPoliciesQueries = {
  [TYPE_ISSUE]: {
    query: projectEscalationPoliciesQuery,
  },
};

export const IssuableAttributeType = {
  ...IssuableAttributeTypeFoss,
  Iteration: 'iteration',
  Epic: 'epic',
  EscalationPolicy: 'escalation policy', // eslint-disable-line @gitlab/require-i18n-strings
};

export const LocalizedIssuableAttributeType = {
  ...LocalizedIssuableAttributeTypeFoss,
  Iteration: s__('Issuable|iteration'),
  Epic: s__('Issuable|epic'),
  EscalationPolicy: s__('Issuable|escalation policy'),
};

// The reason we did this conversion is that we want to keep track of the keys via referencing the object itself
// Thus we have to convert value as key, and use is in the method.
export const IssuableAttributeTypeKeyMap = invert(IssuableAttributeType);

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
    subscription: issuableEpicSubscription,
  },
  [IssuableAttributeType.EscalationPolicy]: {
    current: issuableEscalationPolicyQueries,
    list: escalationPoliciesQueries,
  },
};

export const ancestorsQueries = {
  [TYPE_EPIC]: {
    query: epicAncestorsQuery,
  },
};

export const weightQueries = {
  [TYPE_ISSUE]: {
    query: issueWeightQuery,
    mutation: updateIssueWeightMutation,
    subscription: issuableWeightSubscription,
  },
};

export const healthStatusQueries = {
  [TYPE_ISSUE]: {
    mutation: updateStatusMutation,
    query: issueHealthStatusQuery,
  },
  [TYPE_EPIC]: {
    mutation: updateStatusMutation,
    query: issueHealthStatusQuery,
  },
};

export function dropdowni18nText(issuableAttribute, issuableType) {
  let noAttributesFound = s__('DropdownWidget|No %{issuableAttribute} found');

  if (issuableAttribute === LocalizedIssuableAttributeType.Iteration) {
    noAttributesFound = s__('DropdownWidget|No open %{issuableAttribute} found');
  }

  return {
    ...dropdowni18nTextFoss(issuableAttribute, issuableType),
    noAttributesFound: sprintf(noAttributesFound, {
      issuableAttribute,
    }),
  };
}

export const i18nHelpText = {
  title: s__('IncidentManagement|Page your team with escalation policies'),
  detail: s__(
    'IncidentManagement|Use escalation policies to automatically page your team when incidents are created.',
  ),
  linkText: __('Learn more'),
};

export const i18nPolicyText = {
  paged: s__('IncidentManagement|Paged'),
  title: SIDEBAR_ESCALATION_POLICY_TITLE,
  none,
};

export const i18nStatusText = {
  dropdownHeader: s__('IncidentManagement|Assign paging status'),
  dropdownInfo: s__(
    'IncidentManagement|Setting the status to Acknowledged or Resolved stops paging when escalation policies are selected for the incident.',
  ),
  learnMoreShort: __('Learn More.'),
  learnMoreFull: s__('IncidentManagement|Learn more about incident statuses'),
};
