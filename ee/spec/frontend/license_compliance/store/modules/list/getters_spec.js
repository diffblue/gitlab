import { REPORT_STATUS } from 'ee/license_compliance/store/modules/list/constants';
import * as getters from 'ee/license_compliance/store/modules/list/getters';

describe('Licenses getters', () => {
  describe.each`
    getterName       | reportStatus                 | outcome
    ${'isJobSetUp'}  | ${REPORT_STATUS.jobNotSetUp} | ${false}
    ${'isJobSetUp'}  | ${REPORT_STATUS.ok}          | ${true}
    ${'isJobFailed'} | ${REPORT_STATUS.jobFailed}   | ${true}
    ${'isJobFailed'} | ${REPORT_STATUS.noLicenses}  | ${true}
    ${'isJobFailed'} | ${REPORT_STATUS.incomplete}  | ${true}
    ${'isJobFailed'} | ${REPORT_STATUS.ok}          | ${false}
  `('$getterName when report status is $reportStatus', ({ getterName, reportStatus, outcome }) => {
    it(`returns ${outcome}`, () => {
      expect(
        getters[getterName]({
          reportInfo: {
            status: reportStatus,
          },
        }),
      ).toBe(outcome);
    });
  });
});
