import messages from 'ee/vue_shared/security_reports/store/messages';
import * as getters from 'ee/vue_shared/security_reports/store/modules/secret_detection/getters';

const createReport = (config = {}) => ({
  paths: [],
  newIssues: [],
  ...config,
});

describe('groupedSecretDetectionText', () => {
  it("should return the error message if there's an error", () => {
    const report = createReport({ hasError: true });
    const result = getters.groupedSecretDetectionText(report);

    expect(result).toStrictEqual({ message: messages.SECRET_DETECTION_HAS_ERROR });
  });

  it("should return the loading message if it's still loading", () => {
    const report = createReport({ isLoading: true });
    const result = getters.groupedSecretDetectionText(report);

    expect(result).toStrictEqual({ message: messages.SECRET_DETECTION_IS_LOADING });
  });

  it('should call groupedTextBuilder if everything is fine', () => {
    const report = createReport();
    const result = getters.groupedSecretDetectionText(report);

    expect(result).toStrictEqual({
      countMessage: '',
      critical: 0,
      high: 0,
      message: 'Secret detection detected no new vulnerabilities.',
      other: 0,
      status: '',
      total: 0,
    });
  });
});

describe('secretDetectionStatusIcon', () => {
  it("should return `loading` when we're still loading", () => {
    const report = createReport({ isLoading: true });
    const result = getters.secretDetectionStatusIcon(report);

    expect(result).toBe('loading');
  });

  it("should return `warning` when there's an issue", () => {
    const report = createReport({ hasError: true });
    const result = getters.secretDetectionStatusIcon(report);

    expect(result).toBe('warning');
  });

  it('should return `success` when nothing is wrong', () => {
    const report = createReport();
    const result = getters.secretDetectionStatusIcon(report);

    expect(result).toBe('success');
  });
});
