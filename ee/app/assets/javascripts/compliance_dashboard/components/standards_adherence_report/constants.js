import { __, s__ } from '~/locale';

const PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR = 'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR';
const PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITERS = 'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITERS';
const TWO_APPROVALS = 'TWO_APPROVALS';

export const FAIL_STATUS = 'FAIL';
export const NO_STANDARDS_ADHERENCES_FOUND = s__('ComplianceReport|No standards adherences found');

export const STANDARDS_ADHERENCE_CHECK_LABELS = {
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR]: s__(
    'ComplianceStandardsAdherence|Prevent authors as approvers',
  ),
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITERS]: s__(
    'ComplianceStandardsAdherence|Prevent committers as approvers',
  ),
  [TWO_APPROVALS]: s__('ComplianceStandardsAdherence|Two approvals'),
};

export const STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS = {
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that prevents author approved merge requests',
  ),
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITERS]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that prevents merge requests approved by committers',
  ),
  [TWO_APPROVALS]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that requires any merge request to have more than two approvals',
  ),
};

const GITLAB = 'GITLAB';

export const STANDARDS_ADHERENCE_STANARD_LABELS = {
  [GITLAB]: __('GitLab'),
};
