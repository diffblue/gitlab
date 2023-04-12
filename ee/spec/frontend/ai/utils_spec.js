import * as utils from 'ee/ai/utils';
import Api from 'ee/api';

jest.mock('ee/api', () => {
  return {
    requestAIChat: jest.fn(),
  };
});

describe('AI Utils', () => {
  describe('explainCode', () => {
    const filePath = 'fooPath';
    const fileText = 'barText';
    const error = 'Returned Foo Error';
    const returnedMessage = { message: { content: 'Returned Foo' } };
    const returnedError = { message: error };

    beforeEach(() => {
      Api.requestAIChat.mockResolvedValue({
        data: { choices: [returnedMessage] },
      });
    });

    it('generates a request to AIChat endpoint with the passed props', () => {
      utils.explainCode(filePath, fileText);

      expect(Api.requestAIChat).toHaveBeenCalledWith({
        model: 'gpt-3.5-turbo',
        max_tokens: expect.any(Number),
        temperature: expect.any(Number),
        messages: [
          expect.any(Object),
          {
            role: 'user',
            content: expect.stringContaining(filePath) && expect.stringContaining(fileText),
          },
        ],
      });
    });

    it('returns correct prop from the response', async () => {
      const result = await utils.explainCode(filePath, fileText);
      expect(result).toEqual(returnedMessage);
    });

    it('throws an error if the request fails', async () => {
      Api.requestAIChat.mockRejectedValue({ response: { data: { error: returnedError } } });

      await expect(utils.explainCode(filePath, fileText)).rejects.toThrow(error);
    });
  });
});
