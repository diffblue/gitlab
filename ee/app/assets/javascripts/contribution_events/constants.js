import { s__ } from '~/locale';
import {
  EVENT_CREATED_I18N as CE_EVENT_CREATED_I18N,
  EVENT_CLOSED_I18N as CE_EVENT_CLOSED_I18N,
  EVENT_REOPENED_I18N as CE_EVENT_REOPENED_I18N,
  EVENT_COMMENTED_I18N as CE_EVENT_COMMENTED_I18N,
  EVENT_CLOSED_ICONS as CE_EVENT_CLOSED_ICONS,
} from '~/contribution_events/constants';
import { EPIC_NOTEABLE_TYPE } from '~/notes/constants';

// eslint-disable-next-line import/export
export * from '~/contribution_events/constants';

export const TARGET_TYPE_EPIC = 'Epic';

// From app/models/work_items/type.rb#L28
export const WORK_ITEM_ISSUE_TYPE_TEST_CASE = 'test_case';
export const WORK_ITEM_ISSUE_TYPE_REQUIREMENT = 'requirement';
export const WORK_ITEM_ISSUE_TYPE_OBJECTIVE = 'objective';
export const WORK_ITEM_ISSUE_TYPE_KEY_RESULT = 'key_result';

// eslint-disable-next-line import/export
export const EVENT_CREATED_I18N = Object.freeze({
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
});

// eslint-disable-next-line import/export
export const EVENT_CLOSED_I18N = Object.freeze({
  ...CE_EVENT_CLOSED_I18N,
  [TARGET_TYPE_EPIC]: s__('ContributionEvent|Closed Epic %{targetLink} in %{resourceParentLink}.'),
  [WORK_ITEM_ISSUE_TYPE_TEST_CASE]: s__(
    'ContributionEvent|Closed test case %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_REQUIREMENT]: s__(
    'ContributionEvent|Closed requirement %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_OBJECTIVE]: s__(
    'ContributionEvent|Closed objective %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_KEY_RESULT]: s__(
    'ContributionEvent|Closed key result %{targetLink} in %{resourceParentLink}.',
  ),
});

// eslint-disable-next-line import/export
export const EVENT_REOPENED_I18N = Object.freeze({
  ...CE_EVENT_REOPENED_I18N,
  [TARGET_TYPE_EPIC]: s__(
    'ContributionEvent|Reopened Epic %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_TEST_CASE]: s__(
    'ContributionEvent|Reopened test case %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_REQUIREMENT]: s__(
    'ContributionEvent|Reopened requirement %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_OBJECTIVE]: s__(
    'ContributionEvent|Reopened objective %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_KEY_RESULT]: s__(
    'ContributionEvent|Reopened key result %{targetLink} in %{resourceParentLink}.',
  ),
});

// eslint-disable-next-line import/export
export const EVENT_COMMENTED_I18N = Object.freeze({
  ...CE_EVENT_COMMENTED_I18N,
  [EPIC_NOTEABLE_TYPE]: s__(
    'ContributionEvent|Commented on Epic %{noteableLink} in %{resourceParentLink}.',
  ),
});

// eslint-disable-next-line import/export
export const EVENT_CLOSED_ICONS = Object.freeze({
  ...CE_EVENT_CLOSED_ICONS,
  [TARGET_TYPE_EPIC]: 'epic-closed',
});
