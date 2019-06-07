(*
    Copyright 2018–2019 Fernando Borretti <fernando@borretti.me>

    This file is part of Austral.

    Austral is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Austral is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Austral.  If not, see <http://www.gnu.org/licenses/>.
*)

structure Escape : ESCAPE = struct
    datatype escaped_string = EscapedString of string

    fun escapeString s =
        EscapedString (String.implode (escapeList (String.explode s)))
    and escapeList (#"\\" :: #"n" :: rest) = #"\n" :: (escapeList rest)
      | escapeList (#"\\" :: #"r" :: rest) = #"\r" :: (escapeList rest)
      | escapeList (#"\\" :: #"t" :: rest) = #"\t" :: (escapeList rest)
      | escapeList (#"\\" :: #"\"" :: rest) = #"\"" :: (escapeList rest)
      | escapeList (#"\\" :: #"\\" :: rest) = #"\\" :: (escapeList rest)
      | escapeList (#"\\" :: #" " :: rest) = consumeWhitespace (#" " :: rest)
      | escapeList (#"\\" :: #"\n" :: rest) = consumeWhitespace (#" " :: rest)
      | escapeList (#"\\" :: #"\r" :: rest) = consumeWhitespace (#" " :: rest)
      | escapeList (#"\\" :: #"\t" :: rest) = consumeWhitespace (#" " :: rest)
      | escapeList (#"\\" :: #"\v" :: rest) = consumeWhitespace (#" " :: rest)
      | escapeList (#"\\" :: #"\f" :: rest) = consumeWhitespace (#" " :: rest)
      | escapeList (head :: rest) = head :: (escapeList rest)
      | escapeList nil = nil
    and consumeWhitespace (#" "  :: rest) = consumeWhitespace rest
      | consumeWhitespace (#"\n" :: rest) = consumeWhitespace rest
      | consumeWhitespace (#"\r" :: rest) = consumeWhitespace rest
      | consumeWhitespace (#"\t" :: rest) = consumeWhitespace rest
      | consumeWhitespace (#"\v" :: rest) = consumeWhitespace rest
      | consumeWhitespace (#"\f" :: rest) = consumeWhitespace rest
      | consumeWhitespace (#"\\" :: rest) = rest
      | consumeWhitespace _ = raise Fail "Bad whitespace escape sequence"

    fun escapedToString (EscapedString s) =
        s

    fun unescapeString (EscapedString s) =
        String.concat (map unescapeChar (String.explode s))

    and unescapeChar #"\n" = "\\n"
      | unescapeChar #"\r" = "\\r"
      | unescapeChar #"\t" = "\\t"
      | unescapeChar #"\"" = "\\\""
      | unescapeChar #"\\" = "\\\\"
      | unescapeChar c = String.str c
end