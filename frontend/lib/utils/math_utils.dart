// Math utility functions for game calculations

String calculateCorrectAnswer(String question) {
  // Parse the current question to get the numbers and operators
  final parts = question.split(' ');
  print("Calculating correct answer for $question");

  // Handle expressions with 3 operands (e.g., "2 + 3 + 4" or "2 * 3 + 4")
  if (parts.length >= 5) {
    // 3 numbers and 2 operators
    int num1 = int.parse(parts[0]);
    String operator1 = parts[1];
    int num2 = int.parse(parts[2]);
    String operator2 = parts[3];
    int num3 = int.parse(parts[4]);

    // First, evaluate operations according to operator precedence
    // Multiplication and division take precedence over addition and subtraction
    if ((operator1 == '*' || operator1 == '/') &&
        (operator2 == '+' || operator2 == '-')) {
      // Evaluate first operation first
      int intermediateResult = evaluateOperation(num1, operator1, num2);
      print("Result 1: $intermediateResult");
      // Then evaluate second operation

      int thisresult = evaluateOperation(intermediateResult, operator2, num3);
      print("Result 2: $thisresult");
      return thisresult.toString();
    } else if ((operator2 == '*' || operator2 == '/') &&
        (operator1 == '+' || operator1 == '-')) {
      // Evaluate second operation first
      int intermediateResult = evaluateOperation(num2, operator2, num3);
      print("Result 3: $intermediateResult");
      // Then evaluate with first number

      int thisresult = evaluateOperation(num1, operator1, intermediateResult);
      print("Result 4: $thisresult");
      return thisresult.toString();
    } else {
      // If operators have same precedence, evaluate left to right
      int intermediateResult = evaluateOperation(num1, operator1, num2);
      print("Result 5: $intermediateResult");
      int thisresult = evaluateOperation(intermediateResult, operator2, num3);
      print("Result 6: $thisresult");
      return thisresult.toString();
    }
  } else {
    // Handle simple expressions with 2 operands
    int num1 = int.parse(parts[0]);
    String operator = parts[1];
    int num2 = int.parse(parts[2]);

    int thisresult = evaluateOperation(num1, operator, num2);
    print("Result 7: $thisresult");
    return thisresult.toString();
  }
}

int evaluateOperation(int num1, String operator, int num2) {
  print("Evaluating $num1 $operator $num2");
  switch (operator) {
    case '+':
      print("Result: ${num1 + num2}");
      return num1 + num2;
    case '-':
      print("Result: ${num1 - num2}");
      return num1 - num2;
    case '*':
      print("Result: ${num1 * num2}");
      return num1 * num2;
    case '/':
      // Handle division carefully to avoid runtime errors
      if (num2 == 0) {
        throw Exception('Division by zero');
      }
      print("Result: ${num1 ~/ num2}");
      return num1 ~/ num2; // Using integer division
    default:
      throw Exception('Unknown operator: $operator');
  }
}