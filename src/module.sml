(*
    Copyright 2018 Fernando Borretti <fernando@borretti.me>

    This file is part of Boreal.

    Boreal is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Boreal is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Boreal.  If not, see <http://www.gnu.org/licenses/>.
*)

structure Module : MODULE = struct
    open Symbol

    type nicknames = (module_name, module_name) Map.map

    datatype imports = Imports of (symbol_name, module_name) Map.map

    datatype exports = Exports of symbol_name Set.set

    datatype module = Module of module_name * nicknames * imports * exports * string option

    datatype menv = MEnv of (module_name, module) Map.map

    fun moduleName (Module (n, _, _, _, _)) = n
    fun moduleNicknames (Module (_, ns, _, _, _)) = ns
    fun moduleExports (Module (_, _, _, Exports e, _)) = e
    fun moduleImports (Module (_, _, Imports i, _, _)) = i

    val emptyEnv = MEnv (Map.empty)

    fun addModule (MEnv map) m =
        MEnv (Map.iadd map (moduleName m, m))

    fun envGet (MEnv map) n =
        Map.get map n

    fun resolveNickname (m: module) (n: module_name) =
        case Map.get (moduleNicknames m) n of
            SOME n => n
          | NONE => n

    fun sourceModule menv m s =
        (* See if the current module imports a symbol with this name. If not,
           just return the current module name. If it does, get that module, and
           run sourceModule again on that module to transtively get the original
           module. *)
        case (Map.get (moduleImports m) s) of
            SOME modName => (case (envGet menv modName) of
                                 SOME sourceMod => sourceModule menv sourceMod s
                               | NONE => raise Fail "Module not found in menv")
          | NONE => moduleName m

    fun doesModuleExport (m: module) (s: symbol_name) =
        Set.isIn (moduleExports m) s

    val defaultMenv =
        let val australExports = [
                "progn",
                "let",
                "if",
                "the",
                "allocate",
                "load",
                "store",
                "defun",
                "deftype",
                "defdisjunction",
                "defmodule",
                "in-module",
                "unit",
                "boolean",
                "u8",
                "i8",
                "u16",
                "i16",
                "u32",
                "i32",
                "f32",
                "f64"
            ]
        in
            let val australMod = Module (Ident.mkIdentEx "austral",
                                         Map.empty,
                                         Imports Map.empty,
                                         Exports (Set.fromList (map Ident.mkIdentEx australExports)),
                                         NONE)
            in
                let val australUserMod = Module (Ident.mkIdentEx "austral-user",
                                                 Map.empty,
                                                 (* We import everything austral exports *)
                                                 Imports (Map.fromList (map (fn n => (Ident.mkIdentEx n,
                                                                                      Ident.mkIdentEx "austral"))
                                                                            australExports)),
                                                 Exports Set.empty,
                                                 NONE)
                in
                    addModule (addModule emptyEnv australMod) australUserMod
                end
            end
        end

    (* Defmodule *)

    datatype defmodule_clause = NicknamesClause of (Symbol.symbol_name * Symbol.module_name) list
                              | UseClause of Symbol.module_name list
                              | ImportFromClause of Symbol.module_name * (Symbol.symbol_name list)
                              | ExportClause of Symbol.symbol_name list
                              | DocstringClause of string

    fun resolveModule menv name clauses =
        raise Fail "clauses->defmodule not implemented yet"
end
