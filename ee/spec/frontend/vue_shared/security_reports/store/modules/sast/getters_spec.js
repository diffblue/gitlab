import messages from 'ee/vue_shared/security_reports/store/messages';
import * as getters from 'ee/vue_shared/security_reports/store/modules/sast/getters';

const createReport = (config = {}) => ({
  paths: [],
  newIssues: [],
  ...config,
});

describe('groupedSastText', () => {
  it("should return the error message if there's an error", () => {
    const sast = createReport({ hasError: true });
    const result = getters.groupedSastText(sast);

    expect(result).toStrictEqual({ message: messages.SAST_HAS_ERROR });
  });

  it("should return the loading message if it's still loading", () => {
    const sast = createReport({ isLoading: true });
    const result = getters.groupedSastText(sast);

    expect(result).toStrictEqual({ message: messages.SAST_IS_LOADING });
  });

  it('should call groupedTextBuilder if everything is fine', () => {
    const sast = createReport();
    const result = getters.groupedSastText(sast);

    expect(result).toStrictEqual({
      countMessage: '',
      critical: 0,
      high: 0,
      message: 'SAST detected no new vulnerabilities.',
      other: 0,
      status: '',
      total: 0,
    });
  });
});

describe('sastStatusIcon', () => {
  it("should return `loading` when we're still loading", () => {
    const sast = createReport({ isLoading: true });
    const result = getters.sastStatusIcon(sast);

    expect(result).toBe('loading');
  });

  it("should return `warning` when there's an issue", () => {
    const sast = createReport({ hasError: true });
    const result = getters.sastStatusIcon(sast);

    expect(result).toBe('warning');
  });

  it('should return `success` when nothing is wrong', () => {
    const sast = createReport();
    const result = getters.sastStatusIcon(sast);

    expect(result).toBe('success');
  });
});
