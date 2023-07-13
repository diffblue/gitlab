/* eslint-disable import/export */
export * from '~/diffs/store/getters';

// Returns the code quality degradations for a specific line of a given file
export const fileLineCodequality = (state) => (file, line) => {
  const fileDiff = state.codequalityDiff.files?.[file] || [];
  const lineDiff = fileDiff.filter((violation) => violation.line === line);
  return lineDiff;
};

// Returns the SAST degradations for a specific line of a given file
export const fileLineSast = (state) => (file, line) => {
  const lineDiff = [];
  state?.sastDiff?.added?.map((e) => {
    if (e.location.file === file && e.location.start_line === line) {
      lineDiff.push({
        line: e.location.start_line,
        description: e.description,
        severity: e.severity,
      });
    }
    return e;
  });
  return lineDiff;
};
