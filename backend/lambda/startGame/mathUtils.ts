export interface MathProblem {
  problem: string;
  answer: number;
}

export function generateMathProblem(difficulty: string): MathProblem {
  let operators: string[];
  let maxNumber: number;

  switch (difficulty) {
    case 'easy':
      operators = ['+', '-'];
      maxNumber = 20;
      break;
    case 'medium':
      operators = ['+', '-', '*', '/'];
      maxNumber = 50;
      break;
    case 'hard':
      operators = ['+', '-', '*', '/'];
      maxNumber = 100;
      break;
    default:
      operators = ['+', '-'];
      maxNumber = 20;
  }

  const numOperands = Math.floor(Math.random() * 2) + 2; // 2 or 3 operands
  let problem = [];
  let answer = 0;
  let problemString = '';
  const MAX_NUMBER = 250;
  let iter = 0;
  let redo = true;
  while (redo && iter < 50) {
    iter += 1;

    for (let i = 0; i < numOperands; i++) {
      if (i > 0) {
        const operator = operators[Math.floor(Math.random() * operators.length)];
        problem.push(operator);
      }
      const num = Math.floor(Math.random() * maxNumber) + 1;
      problem.push(num.toString());
    }

    problemString = problem.join(' ');
    answer = evaluateExpression(problemString);
    if (answer > MAX_NUMBER) {
      console.log("answer is too big for problemString", answer, problemString)
      redo = true;
    }
    else if (answer != Math.floor(answer)) {
      console.log("answer is not an integer for problemString", answer, problemString)
      redo = true;
    } else {
      redo = false;
    }
  }
  if (iter == 50) {
    return {
      problem: "1 + 1",
      answer: 2
    };
  }
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
      case '/':
        result /= operand;
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