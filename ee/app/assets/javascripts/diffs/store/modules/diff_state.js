import createStateCE from '~/diffs/store/modules/diff_state';

export default () => ({
  ...createStateCE(),

  endpointCodequality: '',
  codequalityDiff: {},
  endpointSast: '',
  sastDiff: {},
  generateTestFilePath: '',
});
