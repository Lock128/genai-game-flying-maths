import { generateMathProblem, checkAnswer } from './mathUtils';

describe('mathUtils', () => {
  describe('generateMathProblem', () => {
    test('generates a problem with the correct difficulty', () => {
      const easyProblem = generateMathProblem('easy');
      const mediumProblem = generateMathProblem('medium');
      const hardProblem = generateMathProblem('hard');

      expect(easyProblem.problem).toBeDefined();
      expect(mediumProblem.problem).toBeDefined();
      expect(hardProblem.problem).toBeDefined();
    });

    test('throws an error for invalid difficulty', () => {
      expect(() => generateMathProblem('invalid')).toThrow('Invalid difficulty level');
    });
  });

  describe('checkAnswer', () => {
    test('returns correct score for correct answer', () => {
      const score = checkAnswer(10, 10, 15);
      expect(score).toBeGreaterThan(0);
    });

    test('returns 0 for incorrect answer', () => {
      const score = checkAnswer(5, 10, 15);
      expect(score).toBe(0);
    });
  });
});