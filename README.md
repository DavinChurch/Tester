# Tester

This is a small set of utility programs to assist with function-level testing of applications.  Copy any or all of these routines into a namespace containing test case functions (or cross-referenced with them).  These standalone testing programs (implemented as operators) are then called from the application test case functions to perform call-and-return tests.  Executing the test case functions will then perform the coded testing and result validation.

If multiple functions are to be used to perform testing, the included `Test` cover function may be used to call them all in sequence.  It is invoked with a list of function names (in almost any reasonable structure and format) as a right argument, the matching function names in the namespace will be executed.  These names may include an `*` wild-card character, so `Test '*'` will execute all the functions in the workspace.  An optional left argument may be specified to temporarily override the global `StopOnError` setting _(see below)_.  `Test` will return a completion message unless errors are being counted, in which case it will return that count.

## Testing engine

The testing engine consists of three independent, standalone APL operators.  These may be used individually for simple argument/result testing anywhere.  The left operand of each operator is the function to be tested.  The right operand is the expected result.  The derived function uses the provided left and right arguments and passes them directly to the function being tested.  The three routines are:

Tester | Used to...
------ | ----------
`Pass` | Make sure the tested function returns the expected right operand, if a value is specified.  A boolean function may be specified instead which is called monadically with the result to determine if the result is correct.
`Pass_` | Make sure the tested function does NOT return an explicit result in this case.  The right operand must be a boolean function to determine if the tested function produced proper side-effects, or `{1}` is sufficient if no explicit test is to be performed.
`Fail` | Make sure the tested function exits with a `⎕SIGNAL` as validated by the right operand.  The right operand may be text to match `⎕DM`, a numeric (array) for `⎕EN` to be a member of, or a boolean function (provided both of these values) to determine if the failure was as expected.

These routines all respect the setting of an optional global variable named `StopOnError`, which may be set to any of the following values:
`StopOnError` | Function
---- | ----------
`0` | Do not stop, just report invalid results.
`1` | Stop in the testing function on the line that did not validate. _\[Default\]_
`2` | Stop in the tested function at the original error without any error trapping.
`¯1` | Do not stop, and increment global variable "Errors" if it exists.

## Writing application testing functions
Create one or more functions with any desired names that uses these operators for each function call to be tested.  For instance, if a function to be tested is:
```
      3 Plus 4
7
```
Use the simple command:
```
      3 (Plus Pass 7) 4
```
Testing routines may include other code as needed to prepare the tests to be performed, loop through multiple tests, or perform any other desired actions.  A niladic function may be tested by enclosing it in a D-fn and passing a dummy argument.  Remember that when invoking operators, the right operand has short scope and probably needs to be enclosed in parentheses whenever an expression is being used.
