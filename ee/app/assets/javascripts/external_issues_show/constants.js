import { __ } from '~/locale';

export const issueStates = {
  OPENED: 'opened',
  CLOSED: 'closed',
};

export const issueStateLabels = {
  [issueStates.OPENED]: __('Open'),
  [issueStates.CLOSED]: __('Closed'),
};

export const labelsFilterParam = 'labels';
