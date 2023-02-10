import { getTimeago } from '~/lib/utils/datetime_utility';
import { REPORT_STATUS } from './constants';

export const generatedAtTimeAgo = ({ reportInfo: { generatedAt } }) =>
  generatedAt ? getTimeago().format(generatedAt) : '';

export const isJobNotSetUp = (state) => state.reportInfo.status === REPORT_STATUS.jobNotSetUp;
export const isJobFailed = (state) => state.reportInfo.status === REPORT_STATUS.jobFailed;
export const isIncomplete = (state) => state.reportInfo.status === REPORT_STATUS.incomplete;
export const hasNoDependencies = (state) =>
  state.reportInfo.status === REPORT_STATUS.noDependencies;
