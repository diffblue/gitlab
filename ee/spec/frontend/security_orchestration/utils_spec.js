/* eslint-disable no-underscore-dangle */
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import {
  getContentWrapperHeight,
  getPolicyType,
  removeUnnecessaryDashes,
} from 'ee/security_orchestration/utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { mockProjectScanExecutionPolicy } from './mocks/mock_data';

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

    afterEach(() => {
      resetHTMLFixture();
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
