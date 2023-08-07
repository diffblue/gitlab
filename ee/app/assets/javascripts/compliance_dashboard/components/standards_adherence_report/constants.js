import { __, s__ } from '~/locale';

const PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR = 'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR';
const PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS = 'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS';
const AT_LEAST_TWO_APPROVALS = 'AT_LEAST_TWO_APPROVALS';

export const FAIL_STATUS = 'FAIL';
export const NO_STANDARDS_ADHERENCES_FOUND = s__(
  'ComplianceReport|No projects with standards adherence checks found',
);

export const STANDARDS_ADHERENCE_CHECK_LABELS = {
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR]: s__(
    'ComplianceStandardsAdherence|Prevent authors as approvers',
  ),
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS]: s__(
    'ComplianceStandardsAdherence|Prevent committers as approvers',
  ),
  [AT_LEAST_TWO_APPROVALS]: s__('ComplianceStandardsAdherence|At least two approvals'),
};

export const STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS = {
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that prevents author approved merge requests',
  ),
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that prevents merge requests approved by committers',
  ),
  [AT_LEAST_TWO_APPROVALS]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that requires any merge request to have more than two approvals',
  ),
};

const GITLAB = 'GITLAB';

export const STANDARDS_ADHERENCE_STANARD_LABELS = {
  [GITLAB]: __('GitLab'),
};
