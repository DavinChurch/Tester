# Summary

This is a **tiny** set of utility programs to assist with function-level testing of application functions using a very simple syntax and programming interface. However, it is not limited to single functions - it also tests all the function's subroutines implicitly at the same time, so running a test on a top-level function can functionally test as much as an entire application. Test lower-level functions individually to make sure that details and unusual circumstances are handled correctly as well as higher-level functions to make sure everything works together properly. And each testing function can make many different tests sequentially, effectively the same as a testing script would do, and it can perform other operations at the same time such as preparation and cleanup of the testing environment. See below for notes on testing for side-effects (such as changes to files or databases), niladic functions, operators, variations on reporting problems, integrating it into larger environments, and the like. A great deal of flexibility and capability is available when using these utilities.

Copy any or all of these routines into a namespace containing test case (testing) functions (or cross-referenced with them). Such testing and tested functions may be tradfns, Dfns, or more esoteric constructions, as desired. These completely stand-alone testing-management programs (implemented as programmed operators) are then called from the application's testing function(s) to perform the call-and-return test(s) as written. Executing the testing function(s) will then perform all the coded testing and result validations. The testing function(s) may be of any size or complexity or call subroutines or external procedures, and may call functions to be tested that are either low-level or high-level. Notice that a testing function does not require any verbose :IF-work or similar constructs to check results; all input and validation work is done with a single expression using the function call being tested. This makes the testing process easy to code without any extraneous handling and much simpler to read afterwards.

*Please note the difference between similar terms that are used in this document. The **tested** function is the application program that needs to be tested. The **testing** function is the function that calls these operators to perform and validate specific test cases on the **tested** function. These operators are themselves called the **Tester** operators.*

# Tester engine

The Tester engine consists of three independent, stand-alone, user-defined operators. These may be used individually for simple argument/result testing anywhere. For any given test case, only one of these operators needs to be used. The left operand of each operator is the function to be tested. The right operand is the expected result (a value or validation function). The derived function (resulting from combining the operator with its operands) uses the provided left and right function arguments and passes them directly to the function being tested. The three operators are:

Tester | Used to...
------ | ----------
`Pass` | Make sure the tested function returns the expected result, which is provided as the right operand value _(if a value is specified)_. Alternatively a boolean function (often an in-line Dfn) may be specified as the right operand which will be called monadically with the result to verify that the result is correct (where it will return `1` if it is correct).
`Pass_` | Make sure the tested function does NOT return an explicit result at all in this case. The right operand must be a boolean function (often an in-line Dfn) to determine if the tested function produced proper side-effects, or `{1}` or `(1⍨)` is sufficient if no explicit verification is to be performed. This situation includes testing a function with a specified explicit result that is never defined.
`Fail` | Make sure the tested function exits with a `⎕SIGNAL` as validated by the right operand. The right operand may be text to match `⊃⎕DM`, a numeric (array) for `⎕EN` to be a member of, or a boolean function  (often an in-line Dfn) which is provided both of these values to validate that the failure was as expected.

Other testing engines often cannot test a function that does not return a result, or produces side-effects, or properly handle (or validate) functions that intentionally or unintentionally produce an explicit APL error. This set of tools provides for all these options.

## Error handling during testing
These routines all respect the setting of an optional namespace-global variable named `StopOnError`, which may be set to any of the following values:

`StopOnError` | Function
---- | ----------
`0` | Do not stop, just report invalid test results to the session (by returning the report as an explicit result).
`1` | Stop in the testing function on the line that did not validate. **_\[Default\]_**
`2` | Stop in the tested function at any original coding error without any error trapping, primarily for developer use when an untrapped error occurs.
`¯1` | Do not stop, and increment (integer) global variable "Errors" if it exists.
`¯2` | Do not stop, and append the error report text to global variable "Errors" if it exists (it will produce a vector of character vectors).
`¯3` | Do not stop, output the report directly to the session, and return a value of `1`; otherwise return a `0`.

This error handling is performed as described if validation fails or if an untrapped APL error occurs during execution of the test. All untrapped APL errors in the tested code are thus reported automatically and no special handling is needed to watch for this situation during the testing process.

This mechanism is useful for both development-level testing and application-level testing, but perhaps each using different `StopOnError` values to indicte failures in a different way. This value can even be changed dynamically during testing so that `0` can be used to continue making all the programmed tests in sequence, but can be briefly changed to `1` or `¯3` when there is a critical test that needs to pass before continuing with remaining tests.

Note that these routines make use of `⎕TRAP` to capture errors within the tested function(s). If those function(s) themselves also make use of `⎕TRAP` then it should be localized to prevent interference with reporting unexpected errors.

## Stopping during testing
These routines also respect the setting of an optional namespace-global variable named `StopOnTest` which may be used to place a `⎕STOP` breakpoint in the code being tested, for use by developers in isolating a problem. It should consist of a simple character vector (or a nested vector of such vectors to specify several stop points) that contains the name of the testing function (e.g. `TestFoo`) that is calling one of the above routines (not the name of the function actually being tested), followed by the desired line number in square brackets.

For instance, if testing function `TestFoo` runs 3 different tests on function `Foo` from its lines 1, 2, and 3, then it is possible to tell the testing to pause for the test on line 2 by specifying `StopOnTest←'TestFoo[2]'`. The stop actually occurs on `Foo[1]` but only when it is being called from `TestFoo[2]`.

If it is desired to specify a particular line of the tested code on which to stop (instead of `[1]`), extend the `StopOnTest` breakpoint notation to include an `@` followed by the function name and line number where the stop is to be placed. For instance, `StopOnTest←'TestFoo[2]@Foo[17]'` will cause the stop to occur on line `[17]` of `Foo` when it is called from line `[2]` of `TestFoo`. This method can also be used to stop on any other subroutine instead by specifying its name after the `@`. Any tested function not in the current namespace should be listed with an appropriate full or relative dotted name.

Remember that any Dfn must have multiple lines in order for it to accept a `⎕STOP` setting. Also, derived functions and primitive functions do not support `⎕STOP` at all. However, if any of these cases (including derived functions) themselves call a user-defined function, then that function may be stopped using the `@` syntax described above.

# Writing unit-testing functions

Create one or more functions with any desired names (e.g. `TestFoo`) that uses these operators for each function call to be tested. For instance, if the `Plus` function is to be tested with:
```
      3 Plus 4
7
```
Include in the testing function (e.g. `TestFoo`) the simple line:
```
      3 (Plus Pass 7) 4
```
This means that `3 Plus 4` will pass the test if it returns `7` for a result.

Calling any function without this syntax will just execute it normally with no testing added.

## Exiting upon failure
In the case where a test failure is to output a report and exit the testing function immediately, one reasonable method is to set `StopOnErrors←¯3` and exit when the returned result is `1`. For instance:
```
      :if 3 (Plus Pass 7) 4 ⋄ :Return ⋄ :Endif
```
Or
```
      →0/⍨3 (Plus Pass 7) 4
```
Or if the testing function is a Dfn, use of a guard provides an even simpler syntax
```
      3 (Plus Pass 7) 4:
```

Of course, setting `StopOnErrors←1` instead and trapping the resulting `⎕SIGNAL` with `⎕TRAP`, `:Trap`, or a Dfn error guard (`::`) is also a fairly easy alternative.

## Testing function notes
* These arbitrary testing routines may include any other code as needed to prepare the tests to be performed (and clean up afterwards), initialize testing arguments, loop through multiple (random or sequential) tests, call subroutines, or perform any other desired actions that APL allows. They may be as large or complex as needed to provide the proper testing environment.
* A niladic function may be tested by enclosing it in a Dfn and passing a dummy right argument.
* If a tested function's result needs to be captured in a variable during the testing process, enclose the tested function call in a Dfn with appropriate ⍺/⍵ arguments and assign the result variable from inside the Dfn.
* In the rare case where an operator needs to be tested, bind it to testing operand(s) to produce a derived function and then use these routines to test the derived function. The same concept applies when testing a function that is itself to be used as an operand; simply bind it to its operator before testing.
* Since these routines are actually operators rather than functions, remember to use parentheses around the operator and its operands or use another mechanism (such as `⊢`) to separate the operands from the tested function's arguments.
* Also remember that when invoking operators, the right operand has short scope and probably needs to be enclosed in parentheses itself whenever a computed expression is used to calculate a validation value as the right operand rather than just a simple value.
* The `⊢` function may be used with Pass to perform a simple value assertion test, such as in `(⊢Pass 7) 3+4`, or a named function may be created to perform a logical assertion check with `Assert←⊢Pass 1`. Of course any error in the argument expression is not captured in such a case, so only the result is being validated.
* The `≡` function may be used with Pass to perform a simple value comparison test, such as in `3 (≡Pass 1) 1+2`, or a named function may be created to perform a value equivalence check with `Matches←≡Pass 1`. Of course any error in the argument expressions are not captured in such a case, so only the results are being compared.
* If the testing function should not be stopped inside with an error (when `StopOnErrors=1`), then an error trap should be specified within the testing function to exit that level of testing in a controlled way, with another `⎕SIGNAL` for instance.

# Repository Organization

This is a member of the [APLTree project](https://github.com/aplteam/apltree) and is also available via the [Tatin package manager](https://github.com/aplteam/Tatin).

## The Distribution Directory
This directory contains a workspace copy of the code for those that desire that form.  However, it is expected that most distribution will be done with the individual source code text files in the Source directory. A namespace script is also available here for those that prefer that distribution mechanism.

## The Source/Tester Directory
This directory contains only the three Tester operators. Any or all of these operators may be imported and used as needed. These operators have no internal or external dependencies (except for the standard ⎕SE.Dyalog.Utils.disp used during error reporting).

## The Source/Testing Directory
This directory contains a few functions used for testing the major facilities of the Tester engine. This process uses Tester itself to run tests on itself! The functions herein are only used for testing the engine and are not needed for any application use. The Test1, Test2, or Test3 functions may be run on demand to verify the operation of the Tester engine.

### Multiple-function testing utility
If multiple testing functions are to be used to perform testing, it is often easier to use a cover function to execute each of them (or a subset of them) in sequence. This directory also contains an example of such a cover function named `Test` to perform that work, simplifying the way that developers may call their testing scenarios. It may be copied into any namespace containing (usually only) the testing functions to be run. It is invoked with a list of function names (in almost any reasonable structure and format) as a right argument, the matching function names in the namespace will be executed. These names may include an "`*`" wild-card character, so `Test '*'` will execute every (niladic, non-value-returning) function in the namespace. An optional left argument to `Test` may be specified to temporarily override the global `StopOnError` setting. `Test` will return a completion message unless errors are being counted or accumulated, in which case it will return that error count or report. The `Test` cover function is provided only as a convenience and example of a parent function and is not required.

# Using Tester as a component in a larger test environment

These routines are designed for easy use in low-level (unit-level) testing processes, but they are not limited there. Of course, each testing function can perform an entire suite of tests and can perform any needed preparation or cleanup internally, and multiple independent testing functions may be called (by hand or under program control). But these functions can also be called by a custom parent process (or multiple layers of parent processes) to provide for more automation capabilities, and this processing may also include its own preparation or cleanup needs. The tests may be run directly from an external system without the use of a formal testing function, as well. Such integration facilities can also be useful at a larger scale, including integrating it into any separate CI/CD process desired.

The simple one-line mechanism by which individual tests are coded makes it trivial to use in a simple environment, unlike many larger packages that require a great deal of configuration and planning ahead for manual use. Testing at both ends of the development process can improve overall quality and speed the overall development cycle and the same tests can be shared between areas. For instance, an individual programmer can execute the testing function(s) directly and without effort during the development process and the same tests can then be included as part of the application-scope testing later. Any large-scale testing process may include calls to these routines trivially to perform the basic tests and report back its success or failure to the larger process. Full-scale packages are usually designed only for final system-level testing using procedures specific to the package in use, whereas Tester can be integrated into any other package needed simply by substituting a testing function into that package's scenario handling and otherwise use the other package's problem reporting system.

Application-scale testing will often include user I/O interactions. While these Tester operators do not perform such I/O testing directly, they can be included as a part of a testing sequence of any other system that might be available. For instance, a global I/O testing system may be prepared and then Tester may be used to invoke the application and capture any errors while the I/O system is watching for incorrect input or output. Or they could be nested the other way, where the I/O tester will start the application as it needs and then its scripts could call these routines to perform specific steps during external control and reporting. In this way, low-level developer testing could be directly included in a larger scale test environment without having to reproduce the tests in different ways.

## Returning results of testing
If a package requires a pass/fail flag to be returned to it, simply pre-define [semi-]global variables `Errors←0` and `StopOnErrors←¯1` in a parent function. Checking the `Errors` value afterwards provides the success/failure indication required, and this information may be returned by the parent function as needed by the calling routines. If failures need to be reported by producing a `⎕SIGNAL`, then set `StopOnErrors←1` and trap any errors that are signalled from the Tester routines. Those errors can be forwarded with another signalling mechanism or simply used as a manual indication of failure. This mechanism is also useful if the testing is to stop upon encountering the first error, rather than continuing to check for additional errors. If failures need to be reported as text without the complexity of error trapping, simply pre-define `Errors←''` and set `StopOnErrors←¯2`. Textual error messages will be accumulated in this variable so if it remains empty afterwards then none of the tests failed.

## Test planning
For good production-level function testing be sure to test all possible situations, both valid and invalid, as well as checking for any error signals that might be produced intentionally. The functions above provide easy ways to handle all of these situations. Try to include tests that exercise every line of application code, if possible. If other sorts of testing are also required, such as user-interface tests, those may be separately included alongside the function-level testing provided by these routines. Of course, these routines can also watch for functional side-effects, such as file or database updates, with an appropriate validation operand function. As long as a larger-scale testing facility can handle executing APL code to run the tests, it can be used to call Tester routines as part of the process.

## Code coverage
If "code coverage" capabilities are needed, simply use any other tool that is desired to analyze the running code and let Tester perform the defined tests for it to report on. The three operators in this set may themselves be ignored, as well as any testing-specific code that has been written, of course.

## Code timing
If "code timing" capabilities are desired, again use any other timing facility desired and let Tester run the tests to be timed. Simply ignore the trivial amount of time needed by these routines or any extra time spent by any custom testing and validation functions.

## Using text code files
If the code to be tested, or the code performing/validating the testing, is stored in external text files rather than in the active APL workspace, simply provide a cover function to bring them into the workspace before starting the tests, even group-by-group if desired. Any packaged tools that are required (including this one) may be pre-loaded at this time as well.

Some testing systems are created with text script files that control the testing, and Tester effectively uses this same mechanism except that the script language is APL itself and the scripts are just functions. If the source code is kept in text files then some of them therefore may also be the testing "scripts" to be used.

## Source code management facilities
The above mechanism is also convenient if tests are to be performed from a source-code management system (such as GitHub) where testing scenarios are automated and apply against the current versions of code that are stored within the system. The code to be tested is retrieved from the appropriate location (including a test branch, for instance) and then the tests are run as above. Of course, the Dyalog interpreter can be started automatically when a particular event is triggered so it can process the source files directly, rather than the testing being initiated from within an already-running interpreter.
