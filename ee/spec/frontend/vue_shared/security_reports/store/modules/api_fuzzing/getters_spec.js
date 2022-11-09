import messages from 'ee/vue_shared/security_reports/store/messages';
import * as getters from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/getters';

const createReport = (config = {}) => ({
  paths: [],
  newIssues: [],
  ...config,
});

describe('groupedApiFuzzingText', () => {
  it("should return the error message if there's an error", () => {
    const apiFuzzing = createReport({ hasError: true });
    const result = getters.groupedApiFuzzingText(apiFuzzing);

    expect(result).toStrictEqual({ message: messages.API_FUZZING_HAS_ERROR });
  });

  it("should return the loading message if it's still loading", () => {
    const apiFuzzing = createReport({ isLoading: true });
    const result = getters.groupedApiFuzzingText(apiFuzzing);

    expect(result).toStrictEqual({ message: messages.API_FUZZING_IS_LOADING });
  });

  it('should call groupedTextBuilder if everything is fine', () => {
    const apiFuzzing = createReport();
    const result = getters.groupedApiFuzzingText(apiFuzzing);

    expect(result).toStrictEqual({
      countMessage: '',
      critical: 0,
      high: 0,
      message: 'API fuzzing detected no new vulnerabilities.',
      other: 0,
      status: '',
      total: 0,
    });
  });
});

describe('apiFuzzingStatusIcon', () => {
  it("should return `loading` when we're still loading", () => {
    const apiFuzzing = createReport({ isLoading: true });
    const result = getters.apiFuzzingStatusIcon(apiFuzzing);

    expect(result).toBe('loading');
  });

  it("should return `warning` when there's an issue", () => {
    const apiFuzzing = createReport({ hasError: true });
    const result = getters.apiFuzzingStatusIcon(apiFuzzing);

    expect(result).toBe('warning');
  });

  it('should return `success` when nothing is wrong', () => {
    const apiFuzzing = createReport();
    const result = getters.apiFuzzingStatusIcon(apiFuzzing);

    expect(result).toBe('success');
  });
});
