import { getHttpString } from 'ee/vue_shared/security_reports/components/helpers';

describe('getHttpString', () => {
  it.each([null, undefined, false])('returns empty string for "%s"', (type) => {
    expect(getHttpString(type)).toBe('');
  });

  it('returns the correct format', () => {
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
});
