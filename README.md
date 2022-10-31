# kl_utils
A repository for all the silly scripts I use for nothing important.

Any script included here is not optimal to any standards and definitely not bug-free. They are silly scripts I wrote in less than an hour each.

## _syntax.rb
Makes the parts that I don't like a bit easier to read. Makes the following transformations:
- `(.sym(...))` becomes `{|it|it.sym(...)}`
- `(... -> ...)` becomes `{|...| ...}`
- `\a[1 2 3]` becomes `[1,2,3]` (works only if every element is a single token
- `\h{1,2,3,4,5,6}` becomes `{1=>2, 3=>4, 5=>6}`, but is more readable.
- `{sym}` becomes `{|it| it.sym}` if `sym` is a method for `it`. Otherwise, it becomes `{|it| sym(it)}`
- `{... -> ...}` becomes `{|it, ...| ...}`
- `o++` becomes `o.succ`
- `o--` becomes `o.pred`

Example:
```
Before:
Dir[ARGV[0]].reject{File.directory?}.map(f -> [File.foreach(f).to_a.size, f]).map(.reverse).each{-> puts "#{it[0]} has #{it[1]} lines."}

After:
Dir[ARGV[0]].reject{|it|File.directory?(it)}.map{|f| [File.foreach(f).to_a.size, f]}.map{|it|it.reverse}.each{|it| puts "#{it[0]} has #{it[1]} lines."}
```

The real reason for doing this is that I found typing `{` and `|` very taxing after a while because I use `map`, `inject`, `filter`, etc. all the time. Plus, I think that the arrows from Java streams or the `\ .` lambda syntax from Haskell are much more beautiful than what Ruby uses.

Also, it annoys me that `(&:...)` exists (like `array.map(&:to_i)`), but I can't give any arguments to it (like `array.map(&:to_i(2))`. 

## _preprocessor.rb
Kind of enables the preprocessor from C-compilers. The directives can be inserted into code like so:
```
#pre
#define __ONE 1
#endpre
```
It also automatically inserts the usual "guards" (`#ifndef myfile`)
