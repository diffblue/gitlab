import {
  TARGET_TYPE_EPIC,
  WORK_ITEM_ISSUE_TYPE_TEST_CASE,
  WORK_ITEM_ISSUE_TYPE_REQUIREMENT,
  WORK_ITEM_ISSUE_TYPE_OBJECTIVE,
  WORK_ITEM_ISSUE_TYPE_KEY_RESULT,
} from 'ee/contribution_events/constants';
import {
  findCreatedEvent,
  findWorkItemCreatedEvent,
  findClosedEvent,
  findWorkItemClosedEvent,
} from 'jest/contribution_events/utils';

export const eventEpicCreated = findCreatedEvent(TARGET_TYPE_EPIC);

export const eventTestCaseCreated = findWorkItemCreatedEvent(WORK_ITEM_ISSUE_TYPE_TEST_CASE);
export const eventRequirementCreated = findWorkItemCreatedEvent(WORK_ITEM_ISSUE_TYPE_REQUIREMENT);
export const eventObjectiveCreated = findWorkItemCreatedEvent(WORK_ITEM_ISSUE_TYPE_OBJECTIVE);
export const eventKeyResultCreated = findWorkItemCreatedEvent(WORK_ITEM_ISSUE_TYPE_KEY_RESULT);

export const eventEpicClosed = findClosedEvent(TARGET_TYPE_EPIC);

export const eventTestCaseClosed = findWorkItemClosedEvent(WORK_ITEM_ISSUE_TYPE_TEST_CASE);
export const eventRequirementClosed = findWorkItemClosedEvent(WORK_ITEM_ISSUE_TYPE_REQUIREMENT);
export const eventObjectiveClosed = findWorkItemClosedEvent(WORK_ITEM_ISSUE_TYPE_OBJECTIVE);
export const eventKeyResultClosed = findWorkItemClosedEvent(WORK_ITEM_ISSUE_TYPE_KEY_RESULT);
