import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  getPolicyListUrl,
  getSchemaUrl,
  isPolicyInherited,
  getSinglePolicySchema,
} from 'ee/security_orchestration/components/utils';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { TEST_HOST } from 'helpers/test_constants';

describe(getPolicyListUrl, () => {
  it.each`
    input                                                                | output
    ${{ namespacePath: '' }}                                             | ${`${TEST_HOST}/groups/-/security/policies`}
    ${{ namespacePath: 'test', namespaceType: NAMESPACE_TYPES.GROUP }}   | ${`${TEST_HOST}/groups/test/-/security/policies`}
    ${{ namespacePath: '', namespaceType: NAMESPACE_TYPES.PROJECT }}     | ${`${TEST_HOST}/-/security/policies`}
    ${{ namespacePath: 'test', namespaceType: NAMESPACE_TYPES.PROJECT }} | ${`${TEST_HOST}/test/-/security/policies`}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(getPolicyListUrl(input)).toBe(output);
  });
});

describe(getSchemaUrl, () => {
  it.each`
    namespacePath | namespaceType              | output
    ${'test'}     | ${NAMESPACE_TYPES.PROJECT} | ${`${TEST_HOST}/test/-/security/policies/schema`}
    ${'test'}     | ${NAMESPACE_TYPES.GROUP}   | ${`${TEST_HOST}/groups/test/-/security/policies/schema`}
  `(
    'returns $output when passed $namespacePath and $namespaceType',
    ({ namespacePath, namespaceType, output }) => {
      expect(getSchemaUrl({ namespacePath, namespaceType })).toBe(output);
    },
  );
});

describe(isPolicyInherited, () => {
  it.each`
    input                   | output
    ${undefined}            | ${false}
    ${{}}                   | ${false}
    ${{ inherited: false }} | ${false}
    ${{ inherited: true }}  | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(isPolicyInherited(input)).toBe(output);
  });
});

describe(getSinglePolicySchema, () => {
  let mock;
  const mockNamespacePath = 'test/path';
  const mockSchema = {
    $id: 1,
    title: 'mockSchema',
    description: 'mockDescriptions',
    type: 'Object',
    properties: {
      scan_execution_policy: {
        items: {
          properties: {
            foo: 'bar',
          },
        },
      },
      scan_result_policy: {
        items: {
          properties: {
            fizz: 'buzz',
          },
        },
      },
    },
  };

  const createMockOutput = (policyType) => ({
    $id: mockSchema.$id,
    title: mockSchema.title,
    description: mockSchema.description,
    type: mockSchema.type,
    properties: {
      type: {
        type: 'string',
        description: 'Specifies the type of policy to be enforced.',
        enum: policyType,
      },
      ...mockSchema.properties[policyType].items.properties,
    },
  });

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it.each`
    policyType                                                  | output
    ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter}
    ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult.urlParameter}
  `('returns the appropriate schema on request success for $policyType', async ({ policyType }) => {
    mock.onGet().reply(HTTP_STATUS_OK, mockSchema);

    await expect(
      getSinglePolicySchema({
        namespacePath: mockNamespacePath,
        namespaceType: NAMESPACE_TYPES.PROJECT,
        policyType,
      }),
    ).resolves.toStrictEqual(createMockOutput(policyType));
  });

  it('returns an empty schema on request failure', async () => {
    await expect(
      getSinglePolicySchema({
        namespacePath: mockNamespacePath,
        namespaceType: NAMESPACE_TYPES.PROJECT,
        policyType: POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter,
      }),
    ).resolves.toStrictEqual({});
  });

  it('returns an empty schema on non-existing policy type', async () => {
    await expect(
      getSinglePolicySchema({
        namespacePath: mockNamespacePath,
        namespaceType: NAMESPACE_TYPES.PROJECT,
        policyType: 'non_existent_policy',
      }),
    ).resolves.toStrictEqual({});
  });
});
