export function firstSentenceOfText(text) {
  // Split the text into sentences based on periods, while excluding ellipses
  const sentences = text.split(/(?<![.])\.(?!\.\.)/);

  // If there are no sentences, return the entire text
  if (sentences.length === 0) {
    return text;
  }

  return sentences[0];
}
