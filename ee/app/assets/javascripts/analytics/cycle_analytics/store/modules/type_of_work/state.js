import { TASKS_BY_TYPE_SUBJECT_ISSUE } from '../../../constants';

export default () => ({
  isLoadingTasksByTypeChart: false,
  isLoadingTasksByTypeChartTopLabels: false,

  subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
  selectedLabelIds: [], // TODO: we can remove in https://gitlab.com/gitlab-org/gitlab/-/issues/370085
  selectedLabelNames: [],
  topRankedLabels: [],
  data: [],

  errorCode: null,
  errorMessage: '',
});
