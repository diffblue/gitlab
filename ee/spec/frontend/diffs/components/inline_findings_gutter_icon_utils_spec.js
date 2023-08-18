import { scaleFindings } from 'ee/diffs/components/inline_findings_gutter_icon_utils';
import {
  fiveCodeQualityFindings,
  scale,
} from '../../../../../spec/frontend/diffs/mock_data/inline_findings';

describe('scaleFindings', () => {
  it('should return an object with the contents of the array and a scale property', () => {
    const result = scaleFindings(fiveCodeQualityFindings, scale);

    expect(result).toEqual({
      ...fiveCodeQualityFindings,
      scale,
    });
  });

  it('should work with an empty array', () => {
    const result = scaleFindings([], scale);

    expect(result).toEqual({ scale });
  });
});
