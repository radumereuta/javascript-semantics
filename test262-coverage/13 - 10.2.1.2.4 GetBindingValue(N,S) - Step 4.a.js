// 10.2.1.2.4 GetBindingValue(N,S), Step 4.a

// 4. If value is false, then
//     a. If S is false, return the value undefined, otherwise throw a ReferenceError exception.

// Infeasible. (provided that we have only the standard built-in objects, but no host object which is implementation-dependent.)
//
// GetBindingValue is only used by GetValue when its argument is a reference whose base is an environment record,
// while there are only three cases where a reference is generated:
// - 11.1.2 Identifier Reference
//     In this case, a reference is generated by GetIdentifierReference.
// - 11.2.1 Property Accessors
//     In this case, for a given property accessor expression, 'e.x', it first calculates value of 'e', let say 'v', and returns a reference whose base is 'v'.
// - 11.2.3 Function Calls
//     In this case, if we only consider the standard built-in objects, but not any host objects, then no reference is generated in a function call.
//
// Now we can have the following case analysis:
// - In the first case, GetIdentifierReference returns a valid reference only if [[HasBinding]] (in this object environment record, it is implemented by [[HasProperty]]) is true,
//     otherwise it returns an invalid reference whose base is undefined, in which case GetBindingValue is not called.
//     Thus, if GetBindingValue is called, 'value' of Step 4 is always true.
// - In the second case, 'v' is not an environment record, because an environment record is not of type of a value,
//     thus GetBindingValue is not called at all in this case.
// - In the third case, given the pre-condition, it cannot generate a reference.
// Therefore, in any case, it cannot reach this step.