import { __ } from '~/locale';

export const BRANCH_FETCH_DELAY = 250;
export const ALL_BRANCHES = {
  id: null,
  name: __('All branches'),
};

export const EMPTY_STATUS_CHECK = {
  name: '',
  protectedBranches: [],
  externalUrl: '',
};

export const URL_TAKEN_SERVER_ERROR = 'External url has already been taken';
export const NAME_TAKEN_SERVER_ERROR = 'Name has already been taken';
