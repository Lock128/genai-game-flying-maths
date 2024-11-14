export interface MathProblem {
  problem: string;
  answer: number;
}

export function generateMathProblem(difficulty: string): MathProblem {
  const operators = ['+', '-', '*'];
  const numOperands = Math.floor(Math.random() * 2) + 2; // 2 or 3 operands
  let problem = [];
  let answer = 0;

  for (let i = 0; i < numOperands; i++) {
    if (i > 0) {
      const operator = operators[Math.floor(Math.random() * operators.length)];
      problem.push(operator);
    }
    let num: number;
    switch (difficulty) {
      case 'easy':
        num = Math.floor(Math.random() * 10) + 1; // 1 to 10
        break;
      case 'medium':
        num = Math.floor(Math.random() * 90) + 11; // 11 to 100
        break;
      case 'hard':
        num = Math.floor(Math.random() * 900) + 101; // 101 to 1000
        break;
      default:
        throw new Error('Invalid difficulty level');
    }
    problem.push(num.toString());
  }

  const problemString = problem.join(' ');
  answer = evaluateExpression(problemString);

  return {
    problem: problemString,
    answer: answer
  };
}

function evaluateExpression(expression: string): number {
  const parts = expression.split(' ');
  let result = parseInt(parts[0]);
  for (let i = 1; i < parts.length; i += 2) {
    const operator = parts[i];
    const operand = parseInt(parts[i + 1]);
    switch (operator) {
      case '+':
        result += operand;
        break;
      case '-':
        result -= operand;
        break;
      case '*':
        result *= operand;
        break;
    }
  }
  return result;
}

export function checkAnswer(userAnswer: number, correctAnswer: number, timeLeft: number): number {
  if (userAnswer === correctAnswer) {
    // Calculate score based on time left
    return Math.max(10, Math.floor(30 + timeLeft * 2));
  }
  return 0;
}