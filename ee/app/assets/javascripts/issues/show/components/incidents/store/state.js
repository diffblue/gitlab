export default ({ issueIid, projectId } = {}) => ({
  // Initial state
  issueIid,
  projectId,

  // View state
  metricImages: [],
  isLoadingMetricImages: false,
  isUploadingImage: false,
});
