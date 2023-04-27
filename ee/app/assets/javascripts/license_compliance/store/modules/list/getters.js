import { REPORT_STATUS } from './constants';

export const isJobSetUp = (state) => state.reportInfo.status !== REPORT_STATUS.jobNotSetUp;
export const isJobFailed = (state) =>
  [REPORT_STATUS.jobFailed, REPORT_STATUS.noLicenses, REPORT_STATUS.incomplete].includes(
    state.reportInfo.status,
  );
