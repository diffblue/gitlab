import {
  getHttpString,
  getDismissalNoteEventText,
} from 'ee/vue_shared/security_reports/components/helpers';

describe('getHttpString', () => {
  it.each([null, undefined, false])('returns empty string for "%s"', (type) => {
    expect(getHttpString(type)).toBe('');
  });

  it('returns the correct format for request data', () => {
    const request = {
      url: 'http://example.com/requestUrl',
      body: 'request body',
      method: 'request method',
      headers: [
        { name: 'headers name - 1', value: 'headers value - 1' },
        { name: 'headers name - 2', value: 'headers value - 2' },
      ],
    };

    const { url, body, method, headers } = request;

    expect(getHttpString(request)).toBe(
      `${method} ${url}\n${headers[0].name}: ${headers[0].value}\n${headers[1].name}: ${headers[1].value}\n\n${body}`,
    );
  });

  it('returns the correct format for response data', () => {
    const response = {
      body: 'response body',
      statusCode: '200',
      reasonPhrase: 'response reasonPhrase',
      headers: [
        { name: 'response headers name - 1', value: 'response headers value - 1' },
        { name: 'response headers name - 2', value: 'response headers value - 2' },
      ],
    };

    const { body, statusCode, reasonPhrase, headers } = response;

    expect(getHttpString(response)).toBe(
      `${statusCode} ${reasonPhrase}\n${headers[0].name}: ${headers[0].value}\n${headers[1].name}: ${headers[1].value}\n\n${body}`,
    );
  });
});

describe('getDismissalNoteEventText', () => {
  it.each`
    hasProject | hasPipeline | hasDismissalReason | expected
    ${false}   | ${false}    | ${false}           | ${'%{statusStart}Dismissed%{statusEnd}'}
    ${false}   | ${false}    | ${true}            | ${'%{statusStart}Dismissed%{statusEnd}: %{dismissalReason}'}
    ${true}    | ${false}    | ${false}           | ${'%{statusStart}Dismissed%{statusEnd} at %{projectLink}'}
    ${true}    | ${false}    | ${true}            | ${'%{statusStart}Dismissed%{statusEnd}: %{dismissalReason} at %{projectLink}'}
    ${false}   | ${true}     | ${false}           | ${'%{statusStart}Dismissed%{statusEnd} on pipeline %{pipelineLink}'}
    ${false}   | ${true}     | ${true}            | ${'%{statusStart}Dismissed%{statusEnd}: %{dismissalReason} on pipeline %{pipelineLink}'}
    ${true}    | ${true}     | ${false}           | ${'%{statusStart}Dismissed%{statusEnd} on pipeline %{pipelineLink} at %{projectLink}'}
    ${true}    | ${true}     | ${true}            | ${'%{statusStart}Dismissed%{statusEnd}: %{dismissalReason} on pipeline %{pipelineLink} at %{projectLink}'}
  `(
    `returns correct string for hasProject:$hasProject, hasPipeline:$hasPipeline, and hasDismissalReason:$hasDismissalReason`,
    ({ hasProject, hasPipeline, hasDismissalReason, expected }) => {
      expect(getDismissalNoteEventText({ hasProject, hasPipeline, hasDismissalReason })).toBe(
        expected,
      );
    },
  );
});
