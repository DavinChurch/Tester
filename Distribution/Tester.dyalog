﻿:Namespace Tester
(⎕IO ⎕ML ⎕WX)←1 1 3

∇ rpt←{left}(testfn Fail expect)right;at;result;validate;⎕TRAP;nrr;failure;⎕IO;IO;⎕ML;ML;stopon;stopoff
 ⍝ Perform a unit-test on a simple function call that takes arguments and returns a result.
 ⍝ Execute <testfn> with arguments {left} and <right> and expect it to ⎕SIGNAL an error
 ⍝ where ⎕EN∊<expect> (if numeric) or <expect>≡⊃⎕DM (if character).
 ⍝ It is not expected to fail inside of the testing function itself, only by using ⎕SIGNAL.
 ⍝ <expect> may be a data value to match (as above) or a function that will validate
 ⍝ the error that was produced (where arguments provided are ⍺←⎕EN and ⍵←⊃⎕DM) and return
 ⍝ a 1 if the error was expected and 0 if not.
 ⍝ A global variable StopOnError may be set to any of the following values
 ⍝  0←Do not stop, just report invalid results (by returning the report as an explicit result).
 ⍝  1←Stop in the testing function on the line that did not validate. [Default]
 ⍝  2←Stop in the tested function at any original coding error without any error trapping.
 ⍝  ¯1←Do not stop, and increment (integer) global variable "Errors" if it exists.
 ⍝  ¯2←Do not stop, and append the error report text to global variable "Errors" if it exists.
 ⍝  ¯3←Do not stop, output the report directly to the session, and return a value of 1; otherwise return a 0.
 ⍝ See also ∇Pass/∇Pass_ to run tests that do not signal errors.

 IO←⎕IO ⋄ ML←⎕ML ⋄ ⎕IO←⎕ML←1 ⋄ rpt←0 0⍴'' ⋄ at←⊃⎕AT'testfn' ⋄ nrr←at[1]=0 ⋄ stopon←stopoff←⍬
 'Test-fn is niladic'⎕SIGNAL 2/⍨at[2]=0
 'Test-fn is monadic'⎕SIGNAL 2/⍨(at[2]=1)∧0≠⎕NC'left'
 'Test-fn is dyadic'⎕SIGNAL 2/⍨(at[2]=2)∧0=⎕NC'left'
 :If 0=⎕NC'left' ⋄ left←⊢ ⋄ :EndIf
 :Select ⊃⎕NC'expect'
 :Case 2 ⍝ A data value to match the result
     :If (10|⎕DR expect)∊0 2
         validate←{expect≡⍵} ⍝ ⊃⎕DM comparison
     :Else
         validate←{⍺∊expect} ⍝ ⎕EN comparison
     :EndIf
 :Case 3 ⍝ A function to validate the result
     at←⊃⎕AT'expect'
     'Validation-fn does not return a result'⎕SIGNAL 2/⍨at[1]=0
     :Select at[2]
     :Case 0 ⋄ validate←{⎕IO←IO ⋄ ⎕ML←ML ⋄ expect}
     :Case 1 ⋄ validate←{⎕IO←IO ⋄ ⎕ML←ML ⋄ expect ⍵}
     :CaseList 2 ¯2 ⋄ validate←{⎕IO←IO ⋄ ⎕ML←ML ⋄ ⍺ expect ⍵}
     :EndSelect
 :Else
     'Validation operand is not a fn or var'⎕SIGNAL 2
 :EndSelect

 :If 2=⎕NC'StopOnTest' ⍝ Allow ⎕STOP-points to be defined in the tested functions
     :For stopon :In ⊆StopOnTest
         stopon←('['(≠⊆⊢)¨'@'(≠⊆⊢)stopon)~¨¨⊂⊂'[ ]' ⍝ Parse structure: TesterFn[9] or TesterFn[9]@TestedFn[1]
         :If (1 1⊃stopon)≡⊃1↓⎕SI ⋄ :AndIf (⊃⊃(//)⎕VFI 1 2⊃stopon)=⊃1↓⎕LC ⍝ Are we where we want to stop?
             :If 2>≢stopon
                 stopon←(' ∇'~⍨⍕⎕OR'testfn')1 ⍝ Let's stop at the beginning of the tested fn
             :Else
                 stopon←2↑(2⊃stopon),'1' ⋄ stopon[2]←⊃⊃(//)⎕VFI 2⊃stopon ⍝ Where shall we stop?
             :EndIf
             (stopon[2],⎕STOP 1⊃stopon)⎕STOP 1⊃stopon ⋄ stopoff←stopoff,⊂stopon ⍝ Add to existing stops
         :EndIf
     :EndFor
 :EndIf
 failure←0 ⋄ ⎕TRAP←0 'E' '(1↓∊(⎕UCS 13),[⎕IO+.5]⎕DM)⎕SIGNAL(''Fail''≢⊃⎕SI)/⎕EN ⋄ failure←1 ⋄ →⎕LC+1'
 :If 2=⎕NC'StopOnError' ⋄ :AndIf 2∊StopOnError ⋄ ⎕TRAP←0/⎕TRAP ⋄ :EndIf
 ⎕IO←IO ⋄ ⎕ML←ML ⋄ result←left testfn right
 ⎕IO←⎕ML←1 ⋄ ⎕TRAP←0/⎕TRAP
 :For stopon :In stopoff ⋄ (stopon[2]~⍨⎕STOP 1⊃stopon)⎕STOP 1⊃stopon ⋄ :EndFor ⍝ Remove from existing stops

 :If ~failure
     rpt←'Test-fn ran to completion without signalling an error!'
 :ElseIf (⎕EN=6)∧(~(⎕UCS 13)∊⊃⎕DM)∧∨/'left testfn right'⍷⊃1↓⎕DM
     :If 'quadsignal.c'≡⊃⎕DMX.InternalLocation ⍝ Necessary to distinguish an explicit ⎕SIGNAL from a testing problem
         result←⎕EN(⊃⎕DM)
     :Else
         rpt←'Test-fn ran to completion without signalling an error!'
     :EndIf
 :ElseIf (⎕UCS 13)∊⊃⎕DM
     rpt←1↓∊(⎕UCS 13),[1.5](~0,1↓{⍵∨¯1⌽⍵}∨/¨(⊂'left testfn right')⍷¨⎕DM)/⎕DM
 :Else
     result←⎕EN(⊃⎕DM)
 :EndIf

 :If 0∊⍴rpt
     :Trap 0
         :If ~(1⊃result)validate 2⊃result
             rpt←'Validation failed for ⎕SIGNAL #',(⍕1⊃result),':',,(⎕UCS 13),⍕2⊃result
         :EndIf
     :Else
         rpt←'Validation processing function failed to complete!',∊(⎕UCS 13),[1.5]⎕DM
     :EndTrap
 :EndIf

 :If ~0∊⍴rpt
     :If 0=⎕NC'StopOnError' ⋄ :OrIf 1∊StopOnError ⋄ rpt ⎕SIGNAL 500 ⋄ :EndIf
     rpt,⍨←(⊃1↓⎕LC){⍵,(×⍴⍵)/'[',(⍕⍺),']: '}' '~⍨⊃1↓⎕SI
     :If 2=⎕NC'StopOnError' ⋄ :AndIf ∨/¯1 ¯2∊StopOnError ⋄ :AndIf 2=⎕NC'Errors'
         :Select StopOnError ⋄ :Case ¯1 ⋄ Errors+←1 ⋄ :Case ¯2 ⋄ Errors,←⊂rpt ⋄ :EndSelect
     :EndIf
 :EndIf
 :If 2=⎕NC'StopOnError' ⋄ :AndIf ¯3∊StopOnError
     :If 0∊⍴rpt ⋄ rpt←0 ⋄ :Else ⋄ ⎕←rpt ⋄ rpt←1 ⋄ :EndIf
 :EndIf
∇

∇ rpt←{left}(testfn Pass expect)right;at;result;validate;⎕TRAP;failure;⎕IO;IO;⎕ML;ML;stopon;stopoff
 ⍝ Perform a unit-test on a simple function call that takes arguments and returns a result.
 ⍝ Execute <testfn> with arguments {left} and <right> and expect a result back that should ≡ <expect>.
 ⍝ <expect> may be a data value to match (≡) or a niladic or monadic function to validate the
 ⍝ returned result (and return a 1 if OK, 0 if not).
 ⍝ A global variable StopOnError may be set to any of the following values
 ⍝  0←Do not stop, just report invalid results (by returning the report as an explicit result).
 ⍝  1←Stop in the testing function on the line that did not validate. [Default]
 ⍝  2←Stop in the tested function at any original coding error without any error trapping.
 ⍝  ¯1←Do not stop, and increment (integer) global variable "Errors" if it exists.
 ⍝  ¯2←Do not stop, and append the error report text to global variable "Errors" if it exists.
 ⍝  ¯3←Do not stop, output the report directly to the session, and return a value of 1; otherwise return a 0.
 ⍝ See also ∇Pass_ to run tests without expected result values
 ⍝ and ∇Fail to test production of ⎕SIGNAL error reports.

 IO←⎕IO ⋄ ML←⎕ML ⋄ ⎕IO←⎕ML←1 ⋄ rpt←0 0⍴'' ⋄ at←⊃⎕AT'testfn' ⋄ stopon←stopoff←⍬
 'Test-fn cannot return a result -- try using ∇Pass_'⎕SIGNAL 2/⍨at[1]=0
 'Test-fn is niladic'⎕SIGNAL 2/⍨at[2]=0
 'Test-fn is monadic'⎕SIGNAL 2/⍨(at[2]=1)∧0≠⎕NC'left'
 'Test-fn is dyadic'⎕SIGNAL 2/⍨(at[2]=2)∧0=⎕NC'left'
 :If 0=⎕NC'left' ⋄ left←⊢ ⋄ :EndIf
 :Select ⊃⎕NC'expect'
 :Case 2 ⍝ A data value to match the result
     validate←expect∘≡
 :Case 3 ⍝ A function to validate the result
     at←⊃⎕AT'expect'
     'Validation-fn does not return a result'⎕SIGNAL 2/⍨at[1]=0
     :Select at[2]
     :Case 0 ⋄ validate←{⎕IO←IO ⋄ ⎕ML←ML ⋄ expect}
     :CaseList 1 ¯2 ⋄ validate←{⎕IO←IO ⋄ ⎕ML←ML ⋄ expect ⍵}
     :Case 2 ⋄ 'Validation-fn is dyadic'⎕SIGNAL 2
     :EndSelect
 :Else
     'Validation operand is not a fn or var'⎕SIGNAL 2
 :EndSelect

 :If 2=⎕NC'StopOnTest' ⍝ Allow ⎕STOP-points to be defined in the tested functions
     :For stopon :In ⊆StopOnTest
         stopon←('['(≠⊆⊢)¨'@'(≠⊆⊢)stopon)~¨¨⊂⊂'[ ]' ⍝ Parse structure: TesterFn[9] or TesterFn[9]@TestedFn[1]
         :If (1 1⊃stopon)≡⊃1↓⎕SI ⋄ :AndIf (⊃⊃(//)⎕VFI 1 2⊃stopon)=⊃1↓⎕LC ⍝ Are we where we want to stop?
             :If 2>≢stopon
                 stopon←(' ∇'~⍨⍕⎕OR'testfn')1 ⍝ Let's stop at the beginning of the tested fn
             :Else
                 stopon←2↑(2⊃stopon),'1' ⋄ stopon[2]←⊃⊃(//)⎕VFI 2⊃stopon ⍝ Where shall we stop?
             :EndIf
             (stopon[2],⎕STOP 1⊃stopon)⎕STOP 1⊃stopon ⋄ stopoff←stopoff,⊂stopon ⍝ Add to existing stops
         :EndIf
     :EndFor
 :EndIf
 failure←0 ⋄ ⎕TRAP←0 'E' '(1↓∊(⎕UCS 13),[⎕IO+.5]⎕DM)⎕SIGNAL(''Pass''≢⊃⎕SI)/⎕EN ⋄ failure←1 ⋄ →⎕LC+1'
 :If 2=⎕NC'StopOnError' ⋄ :AndIf 2∊StopOnError ⋄ ⎕TRAP←0/⎕TRAP ⋄ :EndIf
 ⎕IO←IO ⋄ ⎕ML←ML ⋄ result←left testfn right
 ⎕IO←⎕ML←1 ⋄ ⎕TRAP←0/⎕TRAP
 :For stopon :In stopoff ⋄ (stopon[2]~⍨⎕STOP 1⊃stopon)⎕STOP 1⊃stopon ⋄ :EndFor ⍝ Remove from existing stops

 :If failure∧(⎕EN=6)∧(~(⎕UCS 13)∊⊃⎕DM)∧∨/'left testfn right'⍷⊃1↓⎕DM
     rpt←'Test-fn did not return a result!'
 :ElseIf failure
     rpt←1↓∊(⎕UCS 13),[1.5](~0,1↓{⍵∨¯1⌽⍵}∨/¨(⊂'left testfn right')⍷¨⎕DM)/⎕DM
 :EndIf

 :If 0∊⍴rpt
     :Trap 0
         :If ~validate result
             rpt←'Validation failed on result:',,(⎕UCS 13),⎕SE.Dyalog.Utils.disp result
         :EndIf
     :Else
         rpt←'Validation processing function failed to complete!',∊(⎕UCS 13),[1.5]⎕DM
     :EndTrap
 :EndIf

 :If ~0∊⍴rpt
     :If 0=⎕NC'StopOnError' ⋄ :OrIf 1∊StopOnError ⋄ rpt ⎕SIGNAL 500 ⋄ :EndIf
     rpt,⍨←(⊃1↓⎕LC){⍵,(×⍴⍵)/'[',(⍕⍺),']: '}' '~⍨⊃1↓⎕SI
     :If 2=⎕NC'StopOnError' ⋄ :AndIf ∨/¯1 ¯2∊StopOnError ⋄ :AndIf 2=⎕NC'Errors'
         :Select StopOnError ⋄ :Case ¯1 ⋄ Errors+←1 ⋄ :Case ¯2 ⋄ Errors,←⊂rpt ⋄ :EndSelect
     :EndIf
 :EndIf
 :If 2=⎕NC'StopOnError' ⋄ :AndIf ¯3∊StopOnError
     :If 0∊⍴rpt ⋄ rpt←0 ⋄ :Else ⋄ ⎕←rpt ⋄ rpt←1 ⋄ :EndIf
 :EndIf
∇

∇ rpt←{left}(testfn Pass_ expect)right;at;result;validate;⎕TRAP;nrr;failure;⎕IO;IO;⎕ML;ML;stopon;stopoff
 ⍝ Perform a unit-test on a simple function call that takes arguments and is expected to NOT return a result.
 ⍝ Execute <testfn> with arguments {left} and <right> and expect no result to be returned.
 ⍝ <expect> should be a function (passed ⍬ as any arguments) that validates
 ⍝ any side effects of the proper operation (and returns a 1 if OK, 0 if not).
 ⍝ A global variable StopOnError may be set to any of the following values
 ⍝  0←Do not stop, just report invalid results (by returning the report as an explicit result).
 ⍝  1←Stop in the testing function on the line that did not validate. [Default]
 ⍝  2←Stop in the tested function at any original coding error without any error trapping.
 ⍝  ¯1←Do not stop, and increment (integer) global variable "Errors" if it exists.
 ⍝  ¯2←Do not stop, and append the error report text to global variable "Errors" if it exists.
 ⍝  ¯3←Do not stop, output the report directly to the session, and return a value of 1; otherwise return a 0.
 ⍝ See also ∇Pass to run tests that return result values to be verified.
 ⍝ and ∇Fail to test production of ⎕SIGNAL error reports.

 IO←⎕IO ⋄ ML←⎕ML ⋄ ⎕IO←⎕ML←1 ⋄ rpt←0 0⍴'' ⋄ at←⊃⎕AT'testfn' ⋄ nrr←at[1]=0 ⋄ stopon←stopoff←⍬
 'Test-fn is niladic'⎕SIGNAL 2/⍨at[2]=0
 'Test-fn is monadic'⎕SIGNAL 2/⍨(at[2]=1)∧0≠⎕NC'left'
 'Test-fn is dyadic'⎕SIGNAL 2/⍨(at[2]=2)∧0=⎕NC'left'
 :If 0=⎕NC'left' ⋄ left←⊢ ⋄ :EndIf
 :Select ⊃⎕NC'expect'
 :Case 3 ⍝ A function to validate the result
     at←⊃⎕AT'expect'
     'Validation-fn does not return a result'⎕SIGNAL 2/⍨at[1]=0
     :Select at[2]
     :Case 0 ⋄ validate←{⎕IO←IO ⋄ ⎕ML←ML ⋄ expect}
     :Case 1 ⋄ validate←{⎕IO←IO ⋄ ⎕ML←ML ⋄ expect ⍵}
     :CaseList 2 ¯2 ⋄ validate←{⎕IO←IO ⋄ ⎕ML←ML ⋄ ⍺ expect ⍵}
     :EndSelect
 :Else
     'Validation operand is not a fn'⎕SIGNAL 2
 :EndSelect

 :If 2=⎕NC'StopOnTest' ⍝ Allow ⎕STOP-points to be defined in the tested functions
     :For stopon :In ⊆StopOnTest
         stopon←('['(≠⊆⊢)¨'@'(≠⊆⊢)stopon)~¨¨⊂⊂'[ ]' ⍝ Parse structure: TesterFn[9] or TesterFn[9]@TestedFn[1]
         :If (1 1⊃stopon)≡⊃1↓⎕SI ⋄ :AndIf (⊃⊃(//)⎕VFI 1 2⊃stopon)=⊃1↓⎕LC ⍝ Are we where we want to stop?
             :If 2>≢stopon
                 stopon←(' ∇'~⍨⍕⎕OR'testfn')1 ⍝ Let's stop at the beginning of the tested fn
             :Else
                 stopon←2↑(2⊃stopon),'1' ⋄ stopon[2]←⊃⊃(//)⎕VFI 2⊃stopon ⍝ Where shall we stop?
             :EndIf
             (stopon[2],⎕STOP 1⊃stopon)⎕STOP 1⊃stopon ⋄ stopoff←stopoff,⊂stopon ⍝ Add to existing stops
         :EndIf
     :EndFor
 :EndIf
 failure←0 ⋄ ⎕TRAP←0 'E' '(1↓∊(⎕UCS 13),[⎕IO+.5]⎕DM)⎕SIGNAL(''Pass_''≢⊃⎕SI)/⎕EN ⋄ failure←1 ⋄ →⎕LC+1'
 :If 2=⎕NC'StopOnError' ⋄ :AndIf 2∊StopOnError ⋄ ⎕TRAP←0/⎕TRAP ⋄ :EndIf
 :If nrr
     ⎕IO←IO ⋄ ⎕ML←ML ⋄ left testfn right
     result←⍬ ⍝ This cannot return a result
 :Else
     ⎕IO←IO ⋄ ⎕ML←ML ⋄ result←left testfn right
     :If ~failure
         rpt←'Test-fn produced a result:',(⎕UCS 13),⎕SE.Dyalog.Utils.disp result
     :EndIf
 :EndIf
 ⎕IO←⎕ML←1 ⋄ ⎕TRAP←0/⎕TRAP
 :For stopon :In stopoff ⋄ (stopon[2]~⍨⎕STOP 1⊃stopon)⎕STOP 1⊃stopon ⋄ :EndFor ⍝ Remove from existing stops

 :If failure∧(⎕EN=6)∧(~(⎕UCS 13)∊⊃⎕DM)∧∨/'left testfn right'⍷⊃1↓⎕DM
     result←⍬ ⍝ This is the expected case (a returned VALUE ERROR)
 :ElseIf failure
     rpt←1↓∊(⎕UCS 13),[1.5](~0,1↓{⍵∨¯1⌽⍵}∨/¨(⊂'left testfn right')⍷¨⎕DM)/⎕DM
 :EndIf

 :If 0∊⍴rpt
     :Trap 0
         :If ~⍬ validate ⍬ ⍝ No data is available to pass to the validation function
             rpt←'Test-fn failed validation'
         :EndIf
     :Else
         rpt←'Validation processing function failed to complete!',∊(⎕UCS 13),[1.5]⎕DM
     :EndTrap
 :EndIf

 :If ~0∊⍴rpt
     :If 0=⎕NC'StopOnError' ⋄ :OrIf 1∊StopOnError ⋄ rpt ⎕SIGNAL 500 ⋄ :EndIf
     rpt,⍨←(⊃1↓⎕LC){⍵,(×⍴⍵)/'[',(⍕⍺),']: '}' '~⍨⊃1↓⎕SI
     :If 2=⎕NC'StopOnError' ⋄ :AndIf ∨/¯1 ¯2∊StopOnError ⋄ :AndIf 2=⎕NC'Errors'
         :Select StopOnError ⋄ :Case ¯1 ⋄ Errors+←1 ⋄ :Case ¯2 ⋄ Errors,←⊂rpt ⋄ :EndSelect
     :EndIf
 :EndIf
 :If 2=⎕NC'StopOnError' ⋄ :AndIf ¯3∊StopOnError
     :If 0∊⍴rpt ⋄ rpt←0 ⋄ :Else ⋄ ⎕←rpt ⋄ rpt←1 ⋄ :EndIf
 :EndIf
∇

:EndNamespace 
