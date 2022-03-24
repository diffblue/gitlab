import { parseDependencies } from 'ee/vue_merge_request_widget/extensions/license_compliance/utils';
import { licenses } from './mock_data';

describe('parseDependencies', () => {
  it('generates a string', () => {
    expect(parseDependencies(licenses[1].dependencies)).toBe(
      'websocket-driver, websocket-extensions, xml-name-validator',
    );
  });
});
