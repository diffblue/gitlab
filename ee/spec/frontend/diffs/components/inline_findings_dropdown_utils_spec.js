import { firstSentenceOfText } from 'ee/diffs/components/inline_findings_dropdown_utils';

describe('firstSentenceOfText', () => {
  it('should return the first sentence ending with a period', () => {
    const description =
      "Unused method argument - `g`. If it's necessary, use `_` or `_g` as an argument name to indicate that it won't be used.";
    expect(firstSentenceOfText(description)).toBe('Unused method argument - `g`');
  });

  it('should not split on ellipses', () => {
    const description = 'This is an example... It continues here.';
    expect(firstSentenceOfText(description)).toBe('This is an example... It continues here');
  });

  it('should handle a single sentence without a period', () => {
    const description = 'This is a single sentence without a period';
    expect(firstSentenceOfText(description)).toBe(description);
  });

  it('should handle an empty string', () => {
    const description = '';
    expect(firstSentenceOfText(description)).toBe('');
  });
});
