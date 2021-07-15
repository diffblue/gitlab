import { __ } from '~/locale';

export const BRANCHES_PER_PAGE = 20;
export const PROJECTS_PER_PAGE = 20;

export const I18N_NEW_BRANCH_FORM = {
  pageTitle: __('New branch'),
  labels: {
    projectDropdown: __('Project'),
    branchNameInput: __('Branch name'),
    sourceBranchDropdown: __('Source branch'),
  },
  formSubmitButtonText: __('Create branch'),
};

export const CREATE_BRANCH_ERROR_GENERIC = __('Failed to create branch. Please try again.');
export const CREATE_BRANCH_ERROR_WITH_CONTEXT = __('Failed to create branch.');

export const CREATE_BRANCH_SUCCESS_ALERT = {
  title: __('New branch was successfully created.'),
  message: __('You can now close this window and return to Jira.'),
};
