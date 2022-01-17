/* eslint-disable no-underscore-dangle */
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import {
  getContentWrapperHeight,
  getPolicyType,
  isValidEnvironmentId,
  removeUnnecessaryDashes,
} from 'ee/threat_monitoring/utils';
import { setHTMLFixture } from 'helpers/fixtures';
import { mockScanExecutionPolicy, mockNetworkPoliciesResponse } from './mocks/mock_data';

describe('Threat Monitoring Utils', () => {
  describe('getContentWrapperHeight', () => {
    const fixture = `
      <div>
        <div class="content-wrapper">
          <div class="content"></div>
        </div>
      </div>
    `;

    beforeEach(() => {
      setHTMLFixture(fixture);
    });

    it('returns the height of an element that exists', () => {
      expect(getContentWrapperHeight('.content-wrapper')).toBe('0px');
    });

    it('returns an empty string for a class that does not exist', () => {
      expect(getContentWrapperHeight('.does-not-exist')).toBe('');
    });
  });

  describe('getPolicyType', () => {
    it.each`
      input                                        | output
      ${''}                                        | ${undefined}
      ${'UnknownPolicyType'}                       | ${undefined}
      ${mockNetworkPoliciesResponse[0].__typename} | ${POLICY_TYPE_COMPONENT_OPTIONS.container.value}
      ${mockNetworkPoliciesResponse[1].__typename} | ${POLICY_TYPE_COMPONENT_OPTIONS.container.value}
      ${mockScanExecutionPolicy.__typename}        | ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value}
    `('returns $output when used on $input', ({ input, output }) => {
      expect(getPolicyType(input)).toBe(output);
    });
  });

  describe('isValidEnvironmentId', () => {
    it.each`
      input        | output
      ${-1}        | ${false}
      ${undefined} | ${false}
      ${'0'}       | ${false}
      ${0}         | ${true}
      ${1}         | ${true}
    `('returns $output when used on $input', ({ input, output }) => {
      expect(isValidEnvironmentId(input)).toBe(output);
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
