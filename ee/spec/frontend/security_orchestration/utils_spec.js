/* eslint-disable no-underscore-dangle */
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import { getPolicyType, removeUnnecessaryDashes } from 'ee/security_orchestration/utils';
import { mockProjectScanExecutionPolicy } from './mocks/mock_scan_execution_policy_data';

describe('Threat Monitoring Utils', () => {
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
});
