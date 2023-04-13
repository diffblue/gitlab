import * as utils from 'ee/ai/utils';
import { sprintf } from '~/locale';

describe('AI Utils', () => {
  describe('generatePrompt', () => {
    const filePath = 'fooPath';
    const fileText = 'barText';

    it('generates a prompts based of the file path and text', () => {
      const result = utils.generatePrompt(fileText, filePath);
      const content = sprintf(utils.explainCodePrompt, { filePath, text: fileText });
      const expectedResult = [
        {
          role: 'system',
          content: 'You are a knowledgeable assistant explaining to an engineer',
        },
        { role: 'user', content },
      ];
      expect(result).toEqual(expectedResult);
    });
  });
});
