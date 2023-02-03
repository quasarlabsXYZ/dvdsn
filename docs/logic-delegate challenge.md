# Delegation CTF

The `logic_delegate.cairo` is an easy CTF where only an owner can get votes when they query the right array index. `Owners` can delegate their votes to become the winner of the CTF. 

This CTF is aimed to test three issues: 
1. Understanding the security around `@view` decorator. A function marked `@view` does not mean it cannot write, therefore you should ensure it only reads and not write. 
2. Reading of an array element
3. Logic Issue in delegate (self-delegate) which will be able to make you the winner. 


 