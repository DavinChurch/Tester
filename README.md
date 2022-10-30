# Tester

This is a small set of utility programs to assist with function-level testing of applications using a very simple syntax and programming interface.  Copy any or all of these routines into a namespace containing test case functions (or cross-referenced with them).  These completely stand-alone testing-management programs (implemented as programmed operators) are then called from the application's test case function(s) to perform the call-and-return test(s) as written.  Executing the test case function(s) will then perform all the coded testing and result validations.

If multiple functions are to be used to perform testing, the included `Test` cover function may be used to call them all in sequence.  It is invoked with a list of function names (in almost any reasonable structure and format) as a right argument, the matching function names in the namespace will be executed.  These names may include an `*` wild-card character, so `Test '*'` will execute all the functions in the workspace.  An optional left argument may be specified to temporarily override the global `StopOnError` setting _(see below)_.  `Test` will return a completion message unless errors are being counted, in which case it will return that count.

This is a member of the [APLTree project](https://github.com/aplteam/apltree) and is also available via the [Tatin package manager](https://github.com/aplteam/Tatin).

## Testing engine

The testing engine consists of three independent, stand-alone APL operators.  These may be used individually for simple argument/result testing anywhere.  The left operand of each operator is the function to be tested.  The right operand is the expected result.  The derived function uses the provided left and right arguments and passes them directly to the function being tested.  The three routines are:

Tester | Used to...
------ | ----------
`Pass` | Make sure the tested function returns the expected result, which is provided as the right operand value _(if a value is specified)_.  Alternatively a boolean function may be specified as the right operand which will be called monadically with the result to verify that the result is correct.
`Pass_` | Make sure the tested function does NOT return an explicit result in this case.  The right operand must be a boolean function to determine if the tested function produced proper side-effects, or `{1}` or `(1⍨)` is sufficient if no explicit verification is to be performed.
`Fail` | Make sure the tested function exits with a `⎕SIGNAL` as validated by the right operand.  The right operand may be text to match `⎕DM`, a numeric (array) for `⎕EN` to be a member of, or a boolean function (provided up to both of these values) to validate that the failure was as expected.

### Error handling during testing

These routines all respect the setting of an optional namespace-global variable named `StopOnError`, which may be set to any of the following values:

`StopOnError` | Function
---- | ----------
`0` | Do not stop, just report invalid test results.
`1` | Stop in the testing function on the line that did not validate. **_\[Default\]_**
`2` | Stop in the tested function at the original error without any error trapping.
`¯1` | Do not stop, and increment global variable "Errors" if it exists.

### Stopping during testing

These routines also respect the setting of an optional namespace-global variable named `StopOnTest` which may be used to place a `⎕STOP` breakpoint in the code being tested.  It should consist of a simple character vector (or a nested vector of such vectors to specify several stop points) that contains the name of the testing function (e.g. `TestFoo`) that is calling one of the above routines (not the name of the function actually being tested), followed by the desired line number in square brackets.

For instance, if testing function `TestFoo` runs 3 different tests on function `Foo` from its lines 1, 2, and 3, then you may tell the testing to pause for the test on line 2 by specifying `StopOnTest←'TestFoo[2]'`.  The stop actually occurs on `Foo[1]` but only when it is being called from `TestFoo[2]`.

If you wish to specify a particular line of the tested code on which to stop (instead of `[1]`), extend the `StopOnTest` breakpoint notation to include an `@` followed by the function name and line number where the stop is to be placed.  For instance, `StopOnTest←'TestFoo[2]@Foo[17]'` will cause the stop to occur on line `[17]` of `Foo` when it is called from line `[2]` of `TestFoo`.  This method can also be used to stop on any other subroutine instead by specifying its name after the `@`.  Any tested function not in the current namespace should be listed with an appropriate full or relative dotted name.

Remember that any D-fn must have multiple lines in order for it to accept a `⎕STOP` setting.

## Writing application testing functions
Create one or more functions with any desired names (e.g. `TestFoo`) that uses these operators for each function call to be tested.  For instance, if the `Plus` function is to be tested with:
```
      3 Plus 4
7
```
Include in your testing function (e.g. `TestFoo`) the simple line:
```
      3 (Plus Pass 7) 4
```
This means that `3 Plus 4` will pass the test if it returns `7` for a result.

### Testing function notes
* These arbitrary testing routines may include any other code as needed to prepare the tests to be performed (and clean up afterwards), initialize testing arguments, loop through multiple tests, call subroutines, or perform any other desired actions that APL allows.
* A niladic function may be tested by enclosing it in a D-fn and passing a dummy right argument.
* Since these routines are actually operators rather than functions, remember to use parentheses around the operator and its operands or use another mechanism to separate the operands from the tested function's arguments.
* Also remember that when invoking operators, the right operand has short scope and probably needs to be enclosed in parentheses itself whenever an expression is being used as the right operand rather than a simple value.
* The `⊢` function may be used with Pass to perform a simple value assertion test, such as in `(⊢Pass 7) 3+4`, or a named function may be assigned to perform a logical assertion check with `Assert←⊢Pass 1`.
