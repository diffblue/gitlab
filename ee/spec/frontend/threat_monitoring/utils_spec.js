import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import {
  getContentWrapperHeight,
  getPolicyType,
  removeUnnecessaryDashes,
} from 'ee/threat_monitoring/utils';
import { setHTMLFixture } from 'helpers/fixtures';
import { mockL3Manifest, mockDastScanExecutionManifest } from './mocks/mock_data';

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
      input                            | output
      ${''}                            | ${null}
      ${'ciliumNetworkPolicy'}         | ${null}
      ${mockL3Manifest}                | ${POLICY_TYPE_COMPONENT_OPTIONS.container.value}
      ${mockDastScanExecutionManifest} | ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value}
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
