/* eslint-disable no-underscore-dangle */
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP, TYPENAME_USER } from '~/graphql_shared/constants';
import { GROUP_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import {
  getPolicyType,
  decomposeApproversV2,
  removeUnnecessaryDashes,
} from 'ee/security_orchestration/utils';
import { mockProjectScanExecutionPolicy } from './mocks/mock_scan_execution_policy_data';

// As returned by endpoints based on API::Entities::UserBasic
const userApprover = {
  avatar_url: null,
  id: 1,
  name: null,
  state: null,
  username: 'user name',
  web_url: null,
};

// As returned by endpoints based on API::Entities::PublicGroupDetails
const groupApprover = {
  avatar_url: null,
  id: 2,
  name: null,
  full_name: null,
  full_path: 'full path',
  web_url: null,
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

describe('decomposeApproversV2', () => {
  describe('with mixed approvers', () => {
    it('returns a copy of the input values with their proper type attribute', () => {
      expect(decomposeApproversV2(allApprovers)).toStrictEqual({
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
      expect(decomposeApproversV2(allApprovers)[type].find(({ id }) => id === approver.id)).toEqual(
        expect.objectContaining({ type }),
      );
    });
  });

  it('sets group as a type for group related approvers with snake_case properties', () => {
    expect(decomposeApproversV2([groupApprover])).toStrictEqual({
      [GROUP_TYPE]: [
        {
          ...groupApprover,
          type: GROUP_TYPE,
          value: convertToGraphQLId(TYPENAME_GROUP, groupApprover.id),
        },
      ],
    });
  });

  it('sets group as a type for group related approvers with camelCase properties', () => {
    const camelCaseGroupApprover = {
      ...groupApprover,
      fullPath: groupApprover.fullPath,
      fullName: groupApprover.fullName,
      full_path: undefined,
      full_name: undefined,
    };
    expect(decomposeApproversV2([camelCaseGroupApprover])).toStrictEqual({
      [GROUP_TYPE]: [
        {
          ...camelCaseGroupApprover,
          type: GROUP_TYPE,
          value: convertToGraphQLId(TYPENAME_GROUP, groupApprover.id),
        },
      ],
    });
  });

  it('sets user as a type for user related approvers', () => {
    expect(decomposeApproversV2([userApprover])).toStrictEqual({
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
