import { ALL_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';

export const TEST_PROJECT_ID = '1';
export const TEST_PROTECTED_BRANCHES = [
  { id: 1, name: 'main' },
  { id: 2, name: 'development' },
];
export const TEST_BRANCHES_SELECTIONS = [ALL_BRANCHES, ...TEST_PROTECTED_BRANCHES];
