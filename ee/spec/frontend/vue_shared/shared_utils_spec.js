import { getContentWrapperHeight } from 'ee/vue_shared/shared_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('getContentWrapperHeight', () => {
  const fixture = `
      <div>
        <div class="content-wrapper">
          <div class="content"></div>
        </div>
      </div>
    `;

  beforeEach(() => {
    setHTMLFixture(fixture);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('returns the height of an element that exists', () => {
    expect(getContentWrapperHeight('.content-wrapper')).toBe('0px');
  });

  it('returns an empty string for a class that does not exist', () => {
    expect(getContentWrapperHeight('.does-not-exist')).toBe('');
  });
});
