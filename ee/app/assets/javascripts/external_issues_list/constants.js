import { IssuableStates } from '~/vue_shared/issuable/list/constants';
import { __, s__ } from '~/locale';

export const externalIssuesListEmptyStateI18n = {
  titleWhenFilters: __('Sorry, your filter produced no results'),
  descriptionWhenFilters: __('To widen your search, change or remove filters above'),
  descriptionWhenNoIssues: s__('Integrations|To keep this project going, create a new issue.'),
  filterStateEmptyMessage: {
    [IssuableStates.Opened]: __('There are no open issues'),
    [IssuableStates.Closed]: __('There are no closed issues'),
  },
};
