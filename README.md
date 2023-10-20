# pir
Ashitav4 addon that parses dice rolls (/random) and finds the winner.

```
/pir type <high|low|close|under|over>  -Sets the win condition.
/pir target <#>  -Sets the target roll # for close, under, and over.
/pir ready <none|pt|ls> <in-game minute>  -Warns to prepare for rolling at given minute and begins collecting rolls.
/pir done  -Prints winner.
/pir list  -Prints current type, target, and rollers (highest to lowest).
/pir collect  -Toggles collecting rolls on/off.
/pir clear  -Clears roll list and stops collecting rolls.
/pir find <name>  -Find a roll by name.
/pir remove <name>  -Remove a roll by name.
/pir help  -Displays help information.
```
