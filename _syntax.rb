#!/usr/bin/env ruby
# frozen_string_literal: true

# [\s]                  Spaces
# ,                     Comma
# #.*                   Matches whole comment
# ->                    Lambda-arrow
# \\h{                  Prefix for shorter maps
# \\a\[                 Prefix for comma-less arrays
# [()\[\]{}]            Matches opening and closing brackets.
# \*\*                  Matches **
# <=>                   Matches <=>
# [<>][<>=]?            Matches <, >, <<, >>, <=, >=
# !~                    Matches !~
# =[=~]?                Matches == and =~
# \+\+                  Matches ++ (later re-written into .succ)
# \-\-                  Matches -- (later re-written into .pred)
# [!+\-\*\/\^&\|][=]?   Matches !, +, -, *, /, ^, &, |, !=, +=, -=, *=, /=, ^=, &=, |=
# "(?:\\.|[^\\"])*"?    Matches strings
# [a-zA-Z0-9\._?!&]+    Matches symbols and numbers.
LYRA_REGEX = /([\s]|,|#.*|->|\\h{|\\a\[|[()\[\]{}]|\*\*|<=>|[<>][<>=]?|!~|=[=~]?|\+\+|\-\-|[!+\-\*\/\^&\|][=]?|"(?:\\.|[^\\"])*"?|[a-zA-Z0-9\._?!&]+)/

# Scan the text using RE, remove empty tokens and remove comments.
def tokenize(s)
  s.scan(LYRA_REGEX).flatten.reject { |w| w.empty? || w.start_with?("#") }
end

def prefixed_ast(sym, tokens, level)
  list(sym, make_ast(tokens, level + 1, "", true))
end

def raise_if_unexpected(expected, t, level)
  raise "Unexpected '#{t}'" if level == 0 || expected != t
end

def read_symbol(t)
  t
end

# (... -> ...)            => {|...| ...}
# (.sym(...))             => {|it| it.sym(...)}
def process_list(tks)
  ["("] + tks + [")"]
  if tks[0].start_with?(".")
    ["{|it|it"] + tks + ["}"]
  elsif tks.size == 1 && tks[0].start_with?("&:")
    ["{|it|it." + tks[0][2..] + "}"]
  elsif tks.include?("->")
    i = tks.index "->"
    ["{|"] + tks[0...i] + ["|"] + tks[(i+1)..] + ["}"]
  else
    ["("] + tks + [")"]
  end
end

def process_array(tks)
  ["[", tks.map(&:strip).reject(&:empty?).join(", "),"]"]
end

# {sym}                   => {|it| it.respond_to?(:sym) ? it.send(:sym) : sym(it)}
# {... -> ...}            => {|it, ...| ...}
def process_curlies(tks)
  if tks.size == 1
    ["{|it|it.respond_to?(:\"#{tks[0]}\") ? it.send(:\"#{tks[0]}\") : #{tks[0]}(it)}"]
  elsif tks.include? "->"
    i = tks.index "->"
    a = ["{|it"]
    a << ", " if i != 0
    a += tks[0...i] + ["|"] + tks[(i+1)..] + ["}"]
    a
  else
    ["{|it|"] + tks + ["}"]
  end
end

                                      
def make_ast(tokens, level = 0, expected = "", stop_after_1 = false)
  root = []
  while (t = tokens.shift) != nil
    case t
    when "->"
      root << "->"
    when "\\h{"
      a = ["["] + make_ast(tokens, level + 1, "}") + ["].to_h"]
      root += a
    when "{"
      root += process_curlies(make_ast(tokens, level+1, "}"))
    when "("
      root += process_list(make_ast(tokens, level+1, ")"))
    when ")"
      raise_if_unexpected(expected, t, level)
      return root
    when "\\a["
      root += process_array(make_ast(tokens, level + 1, "]"))
    when "["
      root << "[" << make_ast(tokens, level + 1, "]") << "]"
    when "]"
      raise_if_unexpected(expected, t, level)
      return root
    when "}"
      raise_if_unexpected(expected, t, level)
      return root
    when '"'
      raise LyraError.new("Unexpected '\"'", :"parse-error")
    #when /^(-?0b[0-1]+|-?0x[\da-fA-F]+|-?\d+)$/
    #  root << read_number(t)
    #when /^-?\d+\.\d+$/
    #  root << t.to_f
    #when /^-?\d+\/\d+r$/
    #  root << t.to_r
    when /^"(?:\\.|[^\\"])*"$/
      root << t
    when /^[!+\-\*\/\^&\|][=]?$/
      root << t
    when "++"
      root << ".succ"
    when "--"
      root << ".pred"
    else
      root << read_symbol(t)
    end
    return root[0] if stop_after_1
  end
  raise LyraError.new("Expected ')', got EOF", :"parse-error") if level != 0
  root.join
end

def main(from, to)
  IO.write(to, make_ast(tokenize(IO.read(from))))
end

raise "Requires 2 arguments!" if ARGV.size != 2

main(ARGV[0], ARGV[1])
