import { s__ } from '~/locale';
import { EVENT_CREATED_I18N as CE_EVENT_CREATED_I18N } from '~/contribution_events/constants';

// eslint-disable-next-line import/export
export * from '~/contribution_events/constants';

export const TARGET_TYPE_EPIC = 'Epic';

// From app/models/work_items/type.rb#L28
export const WORK_ITEM_ISSUE_TYPE_TEST_CASE = 'test_case';
export const WORK_ITEM_ISSUE_TYPE_REQUIREMENT = 'requirement';
export const WORK_ITEM_ISSUE_TYPE_OBJECTIVE = 'objective';
export const WORK_ITEM_ISSUE_TYPE_KEY_RESULT = 'key_result';

// eslint-disable-next-line import/export
export const EVENT_CREATED_I18N = {
  ...CE_EVENT_CREATED_I18N,
  [TARGET_TYPE_EPIC]: s__('ContributionEvent|Opened Epic %{targetLink} in %{resourceParentLink}.'),
  [WORK_ITEM_ISSUE_TYPE_TEST_CASE]: s__(
    'ContributionEvent|Opened test case %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_REQUIREMENT]: s__(
    'ContributionEvent|Opened requirement %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_OBJECTIVE]: s__(
    'ContributionEvent|Opened objective %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_KEY_RESULT]: s__(
    'ContributionEvent|Opened key result %{targetLink} in %{resourceParentLink}.',
  ),
};
