/* eslint-disable no-underscore-dangle */
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP, TYPENAME_USER } from '~/graphql_shared/constants';
import { GROUP_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import {
  getPolicyType,
  decomposeApprovers,
  removeUnnecessaryDashes,
} from 'ee/security_orchestration/utils';
import { mockProjectScanExecutionPolicy } from './mocks/mock_scan_execution_policy_data';

const userApprover = {
  avatarUrl: null,
  id: 1,
  name: null,
  state: null,
  username: 'user name',
  webUrl: null,
};

const groupApprover = {
  avatar_url: null,
  id: 2,
  name: null,
  fullName: null,
  fullPath: 'full path',
  webUrl: null,
};

const allApprovers = [userApprover, groupApprover];

describe('getPolicyType', () => {
  it.each`
    input                                        | output
    ${''}                                        | ${undefined}
    ${'UnknownPolicyType'}                       | ${undefined}
    ${mockProjectScanExecutionPolicy.__typename} | ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value}
  `('returns $output when used on $input', ({ input, output }) => {
    expect(getPolicyType(input)).toBe(output);
  });
});

describe('decomposeApprovers', () => {
  describe('with mixed approvers', () => {
    it('returns a copy of the input values with their proper type attribute', () => {
      expect(decomposeApprovers(allApprovers)).toStrictEqual({
        [GROUP_TYPE]: [
          {
            ...groupApprover,
            type: GROUP_TYPE,
            value: convertToGraphQLId(TYPENAME_GROUP, groupApprover.id),
          },
        ],
        [USER_TYPE]: [
          {
            ...userApprover,
            type: USER_TYPE,
            value: convertToGraphQLId(TYPENAME_USER, userApprover.id),
          },
        ],
      });
    });

    it.each`
      type          | approver
      ${USER_TYPE}  | ${userApprover}
      ${GROUP_TYPE} | ${groupApprover}
    `('sets types depending on whether the approver has $type', ({ type, approver }) => {
      expect(decomposeApprovers(allApprovers)[type].find(({ id }) => id === approver.id)).toEqual(
        expect.objectContaining({ type }),
      );
    });
  });

  it('sets group as a type for group related approvers', () => {
    expect(decomposeApprovers([groupApprover])).toStrictEqual({
      [GROUP_TYPE]: [
        {
          ...groupApprover,
          type: GROUP_TYPE,
          value: convertToGraphQLId(TYPENAME_GROUP, groupApprover.id),
        },
      ],
    });
  });

  it('sets user as a type for user related approvers', () => {
    expect(decomposeApprovers([userApprover])).toStrictEqual({
      [USER_TYPE]: [
        {
          ...userApprover,
          type: USER_TYPE,
          value: convertToGraphQLId(TYPENAME_USER, userApprover.id),
        },
      ],
    });
  });
});

describe('removeUnnecessaryDashes', () => {
  it.each`
    input          | output
    ${'---\none'}  | ${'one'}
    ${'two'}       | ${'two'}
    ${'--\nthree'} | ${'--\nthree'}
    ${'four---\n'} | ${'four'}
  `('returns $output when used on $input', ({ input, output }) => {
    expect(removeUnnecessaryDashes(input)).toBe(output);
  });
});
